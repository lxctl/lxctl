package LxctlHelpers::getters;

use strict;
use warnings;

use Lxc::object;

sub get_ip{
        my ($self, $name) = @_;
        my $subname = (caller(0))[3];

        if (!defined($name)) {
                die "$subname: No vmname is given\n";
        }

        my $path = $self->{'lxc'}->get_conf($name, "lxc.rootfs");
        $path = $path . "/etc/network/interfaces";

        open my $config_file, '<', "$path" or return "N/A";

        my @interfaces = <$config_file>;
        my @ip = grep { /address / } @interfaces;
        $ip[0] =~ s/  address //;
        chop($ip[0]);

        close($config_file);

        return "$ip[0]";
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = new Lxc::object;

	return $self;
}

1;
__END__

=head1 NAME

Lxctl::_getters - temporary module, until we split all distro-specific functions to plugins.

=head1 SYNOPSIS

Can get IP from debian/ubuntu containers.

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
