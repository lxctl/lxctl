package Lxctl::plugins::set::base;

use strict;
use warnings;

use Getopt::Long;
use Digest::SHA qw(sha1_hex);

use Lxc::object;
use UNIVERSAL::require;

use Lxctl::helpers::_general;
use Lxctl::helpers::_config;

sub _order { 99 }

my %options;

sub require
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	return $class->SUPER::require;
}

sub mac_create
{
	my ($self, $data) = @_;

	my $mac = sha1_hex($data);
	$mac =~ s/(..)(..)(..)(..).*/F0:$1:$2:$3:$4/;	
	return $mac;
}

sub set_macaddr
{
	my $self = shift;

	if (defined($options{'macaddr'})) {
		print "Setting MAC: $options{'macaddr'}\n";
		$self->{'lxc'}->set_conf($options{'contname'}, "lxc.network.hwaddr", $options{'macaddr'});
		return;	
	}
	defined($options{'contname'}) or return;
	
	my $mac = $self->mac_create($options{'contname'}) . ":01";
	print "Setting MAC: $mac\n";
	$self->{'lxc'}->set_conf($options{'contname'}, "lxc.network.hwaddr", $mac);
	return;
} 

sub set_dns
{
	my $self = shift;

	defined($options{'dns'}) or return;

	print "Setting DNS: $options{'dns'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/resolv.conf", 'nameserver', $options{'dns'});

	return;
}

sub set_searchdomain
{
	my $self = shift;

	defined($options{'searchdomain'}) or return;

	print "Setting search domain: $options{'searchdomain'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/resolv.conf", 'search', $options{'searchdomain'});

	my $hostname = $self->{'helper'}->get_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hostname", "");

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hosts", '127.0.0.1', "$hostname.$options{'searchdomain'} $hostname localhost");

	return;
}

sub set_userpasswd
{
	my $self = shift;

	defined($options{'userpasswd'}) or return;

	print "Setting password for user: $options{'userpasswd'}\n";

	die "Failed to change password!\n\n"
		if system("echo '$options{'userpasswd'}' | chroot $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/ chpasswd");

	return;
}

sub set_rootsz
{
	my $self = shift;

	defined($options{'rootsz'}) or return;

	print "Setting root size: $options{'rootsz'}\n";

	$options{'rootsz'} =~ m/^\+\d+[bBsSkKmMgGtTpPeE]$/ or
		die "Bad size!\n\n";

	die "Failed to resize root LV!\n\n"
		if system("lvextend -L $options{'rootsz'} /dev/$self->{'VG'}/$options{'contname'}");
	die "Failed to resize root filesystem!\n\n"
		if system("resize2fs /dev/$self->{'VG'}/$options{'contname'}");

	return;
}

sub set_cgroup
{
	my ($self, $name, $value) = @_;

	defined($options{$name}) or return;

	print "Setting $name: $options{$name}\n";

	# Commenting out for now. cpu.shares can be any val
#	$options{$name} =~ m/^\d+$/ or
#		die "Bad $name option!\n\n";

	eval {
		$self->{'lxc'}->set_cgroup($options{'contname'}, $value, $options{$name}, 1);

		$self->{'lxc'}->set_conf($options{'contname'}, "lxc.cgroup." . $value, $options{$name});
	} or do {
		print "$@";
		die "Failed to change $name share!\n\n";
	};

	return;
}

sub set_autostart
{
	my $self = shift;

	defined($options{'autostart'}) or return;
	my $autostart = $options{'autostart'};
	my $name = $options{'contname'};

	if ($autostart == 0) {
		print "Removing $name to autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", $name, "");
	} else {
		print "Adding $name to autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", "\"\$", " $name\"");
	}
}

sub new
{
	my $class = shift;
	my $options_ref = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$self->{'helper'} = Lxctl::helpers::_general->new;

	$self->{'ROOTS_PATH'} = $self->{'lxc'}->get_roots_path();
	$self->{'VG'} = $self->{'lxc'}->get_vg();
	$self->{'CONFIG_PATH'} = $self->{'lxc'}->get_config_path();

	%options = %$options_ref;

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
