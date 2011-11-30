package LxctlHelpers::lxcConfGenerator;

use strict;
use warnings;

# TODO:
# Add mac to config
# Add list of allowed devices to config
# Add interfaces to config

use Lxc:object;
use LxctlHelpers::config;

my $config = new LxctlHelpers::config;
my %options = ();

my $yaml_conf_dir;
my $contname;
my $root_path;
my $lxc;
my $lxc_conf_dir;
my $lxc_log_path;
my $lxc_log_level;

sub convert_name
{
	my $class = shift;

	my $o = "lxc.utsname = $options{'contname'}\n";

	$self->{'output'} .= $o;
}

sub convert_paths
{
	my $class = shift;

	my $o = "";
	$o .= "lxc.rootfs = $options{'root'}/rootfs\n";
	$o .= "lxc.mount = $options{'config'}/fstab\n";

	$self->{'output'} .= $o;
}

sub convert_pts
{
	my $class = shift;

	my $o = "";
	$o .= "lxc.tty = $options{'ttys'}\n";
	$o .= "lxc.pts = $options{'pts'}\n";

	$self->{'output'} .= $o;
}

sub convert_devices
{
	my $class = shift;

	my $o = "";
	$o .= "lxc.cgroup.devices.deny a\n"
	for my $d (@$options{'devices'}) {
		$o .= "lxc.cgroup.devices.allow = $d\n"
	}

	$self->{'output'} .= $o;
}

sub convert_network
{
	my $class = shift;

	my $o = "";
	for my $iface (@$options{'interfaces'}) {
		$o .= "lxc.network.type = $iface{'type'}\n"
		$o .= "lxc.network.flags = $iface{'flags'}\n"
		$o .= "lxc.network.link = $iface{'bridge'}\n"
		$o .= "lxc.network.name = $iface{'name'}\n"
		$o .= "lxc.network.mtu = $iface{'mtu'}\n"
		$o .= "lxc.network.hwaddr = $iface{'mac'}\n"
		$o .= "\n";
	}

	$self->{'output'} .= $o;
}

sub convert
{
	my $class = shift;
	%options = push;

	convert_name;
	convert_paths;
	convert_pts;
	convert_devices;
	convert_network;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$lxc = Lxc::object->new;
	$yaml_conf_dir = $lxc->get_yaml_config_path();
	$lxc_conf_dir = $lxc->get_lxc_conf_dir();
	$root_path = $lxc->get_root_mount_path();
	$lxc_log_path = $lxc->get_lxc_log_path();
	$lxc_log_level = $lxc->get_lxc_log_level();

	$self->{'output'} = "";

	return $self;
}

1;
__END__

=head1 AUTHOR

Pavel Potapenkov, E<lt>ppotapenkov@gmail.comE<gt>
Vladimir Smirnov, E<lt>civil.over@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anatoly Burtsev, Pavel Potapenkov, Vladimir Smirnov

This library is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

=cut
