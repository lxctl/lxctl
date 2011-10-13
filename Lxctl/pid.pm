package Lxctl::pid;

use strict;
use warnings;

use Lxc::object;

my %options = ();

my $ssh = new Lxc::object;

sub do
{
	my $self = shift;

	$pid = shift
		or die "What pid should I check?\n\n";

	$pid =~ m/^\d+$/
		or die "That's non a pid. No-no-no-no, don't try to fool me.\n\n";

	open(my $file, '<', "/proc/$pid/cgroup")
		or die "Failed to open /proc/$pid/cgroup.\n\n";

	$line =~ s/^\S+:\S+:(\S+)$/$1/;

	print "Pid $pid is a part of $line.\n";

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
=head1 NAME

Lxctl::destroy

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

Man page by Capitan Obvious.

=head2 EXPORT

None by default.

=head2 Exportable constants

None by default.

=head2 Exportable functions

TODO

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
