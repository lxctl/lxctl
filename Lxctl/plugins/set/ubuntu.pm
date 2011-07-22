package Lxctl::plugins::set::ubuntu;

use strict;
use warnings;

use Getopt::Long;
use Digest::SHA qw(sha1_hex);

use Lxc::object;

use Lxctl::helpers::_general;
use Lxctl::helpers::_config;

sub _order { 70 }

my %options;

sub require
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	return $class->SUPER::require;
}

sub moduleversion
{
	my $self = shift;
	my @status;
	$status[0] = 0;
	$status[1] = "Plugin: \"Ubuntu\" version 0.1\n";
	
	return @status;
}

sub set_hostname
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'hostname'}) or return @status;
	print "Setting hostname: $options{'hostname'}\n";

	open(my $hostname_file, '>', "$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hostname") or do {
		$status[1] = " Failed to open $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hostname!\n\n";
		$status[0] = 2;
		return @status;
	};

	seek $hostname_file,0,0;

	print $hostname_file $options{'hostname'};

	close $hostname_file;

	my $searchdomain = $options{'searchdomain'};
	if (!defined($options{'searchdomain'})) {
		$searchdomain = $self->{'helper'}->get_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/resolv.conf", 'search');
	}

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/hosts", '127.0.0.1', "$options{'hostname'}.$searchdomain $options{'hostname'} localhost");

	return @status;
}

sub set_ipadd
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'ipadd'}) or return @status;

	print "Setting IP: $options{'ipadd'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/network/interfaces", 'address', $options{'ipadd'});

	return @status;
}

sub set_netmask
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'netmask'}) or return @status;

	print "Setting netmask: $options{'netmask'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/network/interfaces", 'netmask', $options{'netmask'});

	return @status;
}

sub set_defgw
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'defgw'}) or return @status;

	print "Setting gateway: $options{'defgw'}\n";

	$self->{'helper'}->change_config("$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/network/interfaces", 'gateway', $options{'defgw'});

	return @status;
}

sub set_tz()
{
	my $self = shift;
	my @status;
	push(@status, 0);
	push(@status, "");

	defined($options{'tz'}) or return @status;

	print "Setting timesone: $options{'tz'}...\n";

	-e "$self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/usr/share/zoneinfo/$options{'tz'}" or die "No such timezone: $options{'tz'}!\n\n";

	if (system("cp $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/usr/share/zoneinfo/$options{'tz'} $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/localtime")) {
			$status[1] = "Failed to change timezone!\n\n";
			$status[0] = 2;
	}

	return @status;
}

sub new
{
	my $class = shift;	
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$self->{'helper'} = Lxctl::helpers::_general->new;

	$self->{'ROOTS_PATH'} = $self->{'lxc'}->get_roots_path();
	$self->{'VG'} = $self->{'lxc'}->get_vg();
	$self->{'CONFIG_PATH'} = $self->{'lxc'}->get_config_path();

	my $options_ref = shift;
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
