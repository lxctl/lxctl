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
	my @status;
	my $mac;
	push(@status, 0);
	push(@status, "");

	if (defined($options{'macaddr'})) {
		$mac = $options{'macaddr'};	
	} else {
		defined($options{'contname'}) or return @status;
	
		$mac = $self->mac_create($options{'contname'}) . ":01";
	}

	print "Setting MAC: $mac\n";
	$self->{'lxc'}->set_conf($options{'contname'}, "lxc.network.hwaddr", $mac);

	return @status;
} 

sub set_dns
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'dns'}) or return @status;

	print "Setting DNS: $options{'dns'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/resolv.conf", 'nameserver', $options{'dns'});

	return @status;
}

sub set_searchdomain
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");


	defined($options{'searchdomain'}) or return @status;

	print "Setting search domain: $options{'searchdomain'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/resolv.conf", 'search', $options{'searchdomain'});

	my $hostname = $self->{'helper'}->get_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hostname", "");

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hosts", '127.0.0.1', "$hostname.$options{'searchdomain'} $hostname localhost");

	return @status;
}

sub set_userpasswd
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'userpasswd'}) or return @status;

	print "Setting password for user: $options{'userpasswd'}\n";

	if (system("echo '$options{'userpasswd'}' | chroot $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/ chpasswd")) {
		$status[1] = "Failed to change password!\n\n";
		$status[0] = 2;
	}

	return @status;
}

sub set_rootsz
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'rootsz'}) or return @status;

	print "Setting root size: $options{'rootsz'}\n";

	$options{'rootsz'} =~ m/^\+\d+[bBsSkKmMgGtTpPeE]$/ or do {
		$status[1] = "Bad size!\n\n";
		$status[0] = 2;
		return @status;
	};

	if (system("lvextend -L $options{'rootsz'} /dev/$self->{'VG'}/$options{'contname'}")) {
		$status[0] = 2;
		$status[1] = "Failed to resize root LV!\n\n";
		return @status;
	}
	
	if (system("resize2fs /dev/$self->{'VG'}/$options{'contname'}")) {
		$status[0] = 2;
		$status[1] = "Failed to resize root filesystem!\n\n";
		return @status;
	}

	return @status;
}

sub set_cgroup
{
	my ($self, $name, $value) = @_;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{$name}) or return @status;

	print "Setting $name: $options{$name}\n";

	# Commenting out for now. cpu.shares can be any val
#	$options{$name} =~ m/^\d+$/ or
#		die "Bad $name option!\n\n";

	eval {
		$self->{'lxc'}->set_cgroup($options{'contname'}, $value, $options{$name}, 1);

		$self->{'lxc'}->set_conf($options{'contname'}, "lxc.cgroup." . $value, $options{$name});
	} or do {
		$status[1] = "$@";
		$status[0] = 2;
	};

	return @status;
}

sub set_autostart
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'autostart'}) or return @status;
	my $autostart = $options{'autostart'};
	my $name = $options{'contname'};

	if ($autostart == 0) {
		print "Removing $name to autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", $name, "");
	} else {
		print "Adding $name to autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", "\"\$", " $name\"");
	}
	return @status;
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
