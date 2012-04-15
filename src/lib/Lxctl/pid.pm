package Lxctl::pid;

use strict;
use warnings;

my %options = ();

sub get_proc_name
{
	my ($self, $pid) = @_;

	open(my $file, '<', "/proc/$pid/comm")
		or die "Failed to open /proc/$pid/comm.\n\n";

	my $line = <$file>;
	chomp $line;

	return $line;
}

sub get_proc_container
{
	my ($self, $pid) = @_;

	open(my $file, '<', "/proc/$pid/cgroup")
		or die "Failed to open /proc/$pid/cgroup.\n\n";

	my $line = <$file>;
	$line =~ s/^\S+:\S+:\/(\S*)$/$1/;
	chomp $line;
	$line = "dom0 process" if $line eq "";

	return $line;
}

sub get_longest_string
{
	my ($self, @arr) = @_;

	my @tmp = sort { length($b) <=> length($a) } @arr;

	return length($tmp[0]);
}

sub do
{
	my $self = shift;

	my $pidlist = shift
		or die "What pid[s] should I check?\n\n";

	my @pids = ('PID');
	my @names = ('NAME');
	my @cts = ('CT_NAME');

	my @tmp_pids = split(/,/, $pidlist);
	for my $pid (@tmp_pids) {
		$pid =~ m/^\d+$/
			or die "$pid - that's not a pid. No-no-no-no, don't try to fool me.\n\n";
		
		push(@pids, $pid);
		push(@names, $self->get_proc_name($pid));
		push(@cts, $self->get_proc_container($pid));
	}

	my $max_pids = $self->get_longest_string(@pids);
	my $max_names = $self->get_longest_string(@names);
	my $max_cts = $self->get_longest_string(@cts);

	for (my $i=0; $i < scalar(@pids); $i++) {
		printf "  %".$max_pids."s  %".$max_names."s  %".$max_cts."s\n", $pids[$i], $names[$i], $cts[$i];
	}

	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	return $self;
}

1;
__END__

=head1 AUTHOR

Anatoly Burtsev, E<lt>anatolyburtsev@yandex.ruE<gt>
Pavel Potapenkov, E<lt>ppotapenkov@gmail.comE<gt>
Vladimir Smirnov, E<lt>civil.over@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anatoly Burtsev, Pavel Potapenkov, Vladimir Smirnov

This library is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

=cut
