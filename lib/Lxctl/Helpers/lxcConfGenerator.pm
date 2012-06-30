package Lxctl::Helpers::lxcConfGenerator;

use strict;
use warnings;
use 5.010001;

# TODO:
# Add mac to config
# Add list of allowed devices to config
# Add interfaces to config

use Lxc::object;
use Lxctl::Helpers::config;
use Lxctl::Helpers::optionsValidator;
use Lxctl::set;
use Data::Dumper;


my $config = new Lxctl::Helpers::config;
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
	my $self = shift;

	my $o = "lxc.utsname = $options{'contname'}\n";
	$o .= "\n";

	$self->{'output'} .= $o;
}

sub convert_cgroup
{
	my $self = shift;
	my $o;

	if (defined($options{'cpu-shapres'})) {
		$o .= "lxc.cgroup.cpu.shares = $options{'cpu-shapres'}\n";
	}
	if (defined($options{'cpus'})) {
		$o .= "lxc.cgroup.cpuset.cpus = $options{'cpus'}\n";
	}
	if (defined($options{'mem'})) {
		$o .= "lxc.cgroup.memory.limit_in_bytes = $options{'mem'}\n";
	}
	if (defined($options{'io'})) {
		$o .= "lxc.cgroup.blkio.weight = $options{'io'}\n";
	}

	$self->{'output'} .= $o;
}

sub convert_paths
{
	my $self = shift;

	my $o = "lxc.rootfs = $options{'root'}/rootfs\n";
	$o .= "lxc.mount = $options{'config'}/fstab\n";
	$o .= "\n";

	$self->{'output'} .= $o;
}

sub convert_pts
{
	my $self = shift;

	my $o = "";
	$o .= "lxc.tty = $options{'ttys'}\n";
	$o .= "lxc.pts = $options{'pts'}\n";
	$o .= "\n";

	$self->{'output'} .= $o;
}

sub convert_devices
{
	my $self = shift;

	my $o = "";
	my %devices = %{$options{'devices'}};
	for my $d (@{$devices{'deny'}}) {
		$o .= "lxc.cgroup.devices.deny = $d\n";
	}

	for my $d (@{$devices{'allow'}}) {
		$o .= "lxc.cgroup.devices.allow = $d\n";
	}

	$o .= "\n";
	$self->{'output'} .= $o;
}

sub convert_network
{
	my $self = shift;

	my $o = "";
	my %iface = %{$options{'interfaces'}};
	$o .= "lxc.network.type = $iface{'type'}\n";
	if ($iface{'extname'} ne '') {
		if ($iface{'type'} eq 'veth') {
			$o .= "lxc.network.veth.pair = $iface{'extname'}\n";
		} elsif ($iface{'type'} eq 'vlan') {
			$o .= "lxc.network.vlan.id = $iface{'extname'}\n";
		}
	}
	$o .= "lxc.network.flags = $iface{'flags'}\n";
	$o .= "lxc.network.link = $iface{'bridge'}\n";
	$o .= "lxc.network.name = $iface{'name'}\n";
	$o .= "lxc.network.mtu = $iface{'mtu'}\n";
	$o .= "lxc.network.hwaddr = $iface{'mac'}\n";
	$o .= "\n";

	$self->{'output'} .= $o;
}

sub convert
{
	my ($self, $opts) = @_;
	die "BUG: Options not passed to lxcConfGenerator!" if (!defined($opts));

	%options = %{$opts};

	$self->convert_name;
	$self->convert_paths;
	$self->convert_pts;
	$self->convert_devices;
	$self->convert_network;

	my $o = $self->{'output'};
	print "$o\n";
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
	$self->{'validator'} = new Lxctl::Helpers::optionsValidator;

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
