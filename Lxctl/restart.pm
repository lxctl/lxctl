package Lxctl::restart;

use strict;
use warnings;

use Lxc::object;

my %options = ();

my $lxc_conf_dir;

sub _actual_start
{
	my ($self, $daemon) = @_;
	$self->{'lxc'}->start($options{'contname'}, $daemon, $lxc_conf_dir."/".$options{'contname'}."/config");
}

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	eval {

		$self->{'lxc'}->stop(1);
		sleep(1);
		my $status = $self->{'lxc'}->status($options{'contname'});
		if ($status eq "RUNNING") {
			$self->{'lxc'}->stop(0);
		}
		print "It seems that \"$options{'contname'}\" is stopped now.\n";

		$self->_actual_start(1);
		sleep(1);
		 $status = $self->{'lxc'}->status($options{'contname'});
		if ($status eq "STOPPED") {
			$self->_actual_start(0);
		}
		print "It seems that \"$options{'contname'}\" was started.\n";
	} or do {
		print "$@";
		die "Cannot restart $options{'contname'}!\n\n";
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
=head1 NAME

Lxctl::restart

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
