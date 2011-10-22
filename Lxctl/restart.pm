package Lxctl::restart;

use strict;
use warnings;

use Lxc::object;
use Lxctl::start;
use Lxctl::stop;

my %options = ();

my $lxc_conf_dir;

use constant {
	TIMEOUT => 30,
};

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	my $stop = new Lxctl::stop;
	my $start = new Lxctl::start;

	eval {
		my $status = $self->{'lxc'}->status($options{'contname'});
		my $cnt = 0;

		while ($status eq "RUNNING" && $cnt < TIMEOUT) {
			$cnt++;
			$stop->do($options{'contname'});
			sleep(1);
			$status = $self->{'lxc'}->status($options{'contname'});
		}

		die "Cannot stop $options{'contname'}.\n\n" if ($cnt == TIMEOUT);

		$start->do($options{'contname'});
		1;
	} or do {
		print "$@";
		die "Cannot restart $options{'contname'}.\n\n";
	};
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();

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
