package Lxctl::set;

use strict;
use warnings;
use autodie qw(:all);

use Getopt::Long;
use Digest::SHA qw(sha1_hex);
use Linux::LVM;

use Lxc::object;

use LxctlHelpers::helper;
use LxctlHelpers::config;

my %options = ();

my $yaml_conf_dir;
my $lxc_conf_dir;
my $root_mount_path;
my $templates_path;
my $vg;
my $config = new LxctlHelpers::config;


sub mac_create
{
	my ($self, $data) = @_;

	my $mac = sha1_hex($data);
	$mac =~ s/(..)(..)(..)(..).*/FC:$1:$2:$3:$4/;	
	return $mac;
}

sub set_hostname
{
	my $self = shift;

	defined($options{'hostname'}) or return;
	print "Setting hostname: $options{'hostname'}\n";

	open(my $hostname_file, '>', "$root_mount_path/$options{'contname'}/rootfs/etc/hostname");

	seek $hostname_file,0,0;

	print $hostname_file $options{'hostname'};

	close $hostname_file;

	my $searchdomain = $options{'searchdomain'};
	if (!defined($options{'searchdomain'})) {
		if ( -e "$root_mount_path/$options{'contname'}/rootfs/etc/resolv.conf" ) {
			$searchdomain = $self->{'helper'}->get_config("$root_mount_path/$options{'contname'}/rootfs/etc/resolv.conf", 'search');
		} else {
			$searchdomain = $config->get_option_from_main('set', 'SEARCHDOMAIN');
		}
	}

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/hosts", '127.0.0.1', "$options{'hostname'}.$searchdomain $options{'hostname'} localhost");

	return;
}

sub set_ipaddr
{
	my $self = shift;

	defined($options{'ipaddr'}) or return;
	if ($options{'ipaddr'} =~ m/\d+\.\d+\.\d+\.\d+\/(\d+)/ ) {
		my $netmask = $self->{'helper'}->cidr2ip($1);
		$options{'netmask'} = $netmask;
	}

	print "Setting IP: $options{'ipaddr'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/network/interfaces", 'address', $options{'ipaddr'});

	return;
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
	$options{'macaddr'} = $mac;
	return;
} 

sub set_netmask
{
	my $self = shift;

	defined($options{'netmask'}) or return;

	print "Setting netmask: $options{'netmask'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/network/interfaces", 'netmask', $options{'netmask'});

	return;
}

sub set_mtu
{
	my $self = shift;

	defined($options{'mtu'}) or return;

	print "Setting mtu: $options{'mtu'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/network/interfaces", 'mtu', $options{'mtu'});
	$self->{'helper'}->change_config("$lxc_conf_dir/$options{'contname'}/config", 'lxc.network.mtu = ', $options{'mtu'});

	return;
}

sub set_ifname
{
	my $self = shift;
	defined($options{'ifname'}) or return;

	if ($options{'ifname'} eq "mac") {
		$options{'ifname'} = $options{'mac'};
		if (!defined($options{'ifname'})) {
			$options{'ifname'} = $config->get_option_from_yaml("$yaml_conf_dir/$options{'contname'}.yaml", "", "macaddr");
		}

		if (!defined($options{'ifname'})) {
			$options{'ifname'} = $self->{'lxc'}->get_conf($options{'contname'}, "lxc.network.hwaddr");
			$options{'macaddr'} = $options{'ifname'};
		}

		$options{'ifname'} =~ s/^..:(.*)/$1/;
		$options{'ifname'} =~ s/://g;

		$options{'ifname'} = "veth" . $options{'ifname'};
	} elsif ($options{'ifname'} eq "ip") {
		if (!defined($options{'ipaddr'})) {
			$options{'ipaddr'} = $config->get_option_from_yaml("$yaml_conf_dir/$options{'contname'}.yaml", "", "ipaddr");
			if (!defined($options{'ipaddr'})) {
				print "No IP address specified, skipping\n";
				return;
			}
		}
		$options{'ifname'} = $options{'ipaddr'};
		$options{'ifname'} =~ s/\d+\.\d+\.(\d+).(\d+)/$1$2/g;
		$options{'ifname'} = "lxc" . $options{'ifname'};
	}

	print "Setting interface (host part) name to $options{'ifname'}\n";	

	my $size = bytes::length($options{'ifname'});

	die "Wow... that thing is big... too big for me! Maximum I know how to handle is 15 bytes\n" if ($size > 15);

	my $old_name;
	my $step = 1;
	eval {
		$old_name = $config->get_option_from_yaml("$yaml_conf_dir/$options{'contname'}.yaml", "", "ifname") or die;
		$step++;
		system("ip link set $old_name down");
		$step++;
		system("ip link set $old_name name $options{'ifname'}");
		$step++;
		system("ip link set $options{'ifname'} up");
		$step++;
		1;
	} or do {
		print "THIS IS NOT FATAL: Failed to do step $step, can't change ifname of interface in runtime. Please, restart container manualy.\n";
	};

	$self->{'helper'}->change_config("$lxc_conf_dir/$options{'contname'}/config", 'lxc.network.name', $options{'ifname'});
	return;
}

sub set_defgw
{
	my $self = shift;

	defined($options{'defgw'}) or return;

	print "Setting gateway: $options{'defgw'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/network/interfaces", 'gateway', $options{'defgw'});

	return;
}

sub set_dns
{
	my $self = shift;

	defined($options{'dns'}) or return;

	print "Setting DNS: $options{'dns'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/resolv.conf", 'nameserver', $options{'dns'});

	return;
}

sub set_searchdomain
{
	my $self = shift;

	defined($options{'searchdomain'}) or return;

	print "Setting search domain: $options{'searchdomain'}\n";

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/resolv.conf", 'search', $options{'searchdomain'});

	my $hostname = $self->{'helper'}->get_config("$root_mount_path/$options{'contname'}/rootfs/etc/hostname", "");

	$self->{'helper'}->change_config("$root_mount_path/$options{'contname'}/rootfs/etc/hosts", '127.0.0.1', "$hostname.$options{'searchdomain'} $hostname localhost");

	return;
}

sub set_userpasswd
{
	my $self = shift;

	defined($options{'userpasswd'}) or return;

	print "Setting password for user: $options{'userpasswd'}\n";

	die "Failed to change password!\n\n"
		if system("echo '$options{'userpasswd'}' | chroot $root_mount_path/$options{'contname'}/rootfs/ chpasswd");

	return;
}

sub set_rootsz
{
	my $self = shift;

	defined($options{'rootsz'}) or return;

	$options{'roottype'} ||= 'lvm';
	if (lc($options{'roottype'}) eq 'file') {
		print "set rootsz is unsupported for root in file\n\n";
		return;
	}

	$options{'rootsz'} =~ m/^[+-]?\d+[.]?\d*[bBsSkKmMgGtTpPeE]/ or die "Bad size!";

	my %lvm_info = get_lv_info("/dev/$vg/$options{'contname'}");
	my $desired_size;

	my $tmp = $lvm_info{'size'};
	if ($options{'rootsz'} =~ m/^[+](.+)+/) {
		print "SET: $1\n";
		$desired_size = $self->{'lxc'}->convert_size($1, $lvm_info{'size_unit'}, 0);
		$desired_size += $lvm_info{'size'};
	} elsif ($options{'rootsz'} =~ m/^-(.*)+/) {
		print "Shrinking is not supported yet\n";
		$desired_size = $self->{'lxc'}->convert_size($1, $lvm_info{'size_unit'}, 0);
		$desired_size = $lvm_info{'size'} - $desired_size;
		if ($desired_size <= 0) {
			print "Can't resize this much!\n";
			return;
		}
	} else {
		$desired_size = $self->{'lxc'}->convert_size($options{'rootsz'}, $lvm_info{'size_unit'}, 0);
	}

	if ($desired_size == $lvm_info{'size'}) {
		print "Already desired size, exiting...\n";
		return;
	} elsif ($desired_size < $lvm_info{'size'}) {
		print "Shrinking is not supported yet\n";
		return;
	}

	$desired_size .= $lvm_info{'size_unit'};

        $options{'rootsz'} = $desired_size;

	print "Setting root size: $desired_size\n";

	(system("lvextend -L $desired_size /dev/$vg/$options{'contname'}") == 0) or die "Failed to extend logical volume.\n\n";
	(system("resize2fs /dev/$vg/$options{'contname'}") == 0) or die "Failed to resize filesystem.\n\n";

	return;
}

sub set_cgroup
{
	my $self = shift;

	my ($name, $value) = @_;

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
		print "Removing $name from autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", $name, "");
	} else {
		print "Adding $name to autostart\n";
		$self->{'helper'}->modify_config("/etc/default/lxc", "CONTAINERS", "\"\$", " $name\"");
	}
}

sub set_tz()
{
	use File::Copy "cp";
	my $self = shift;

	defined($options{'tz'}) or return;

	print "Setting timesone: $options{'tz'}...\n";
	my $cont_root_path = "$root_mount_path/$options{'contname'}/rootfs";

	-e "$cont_root_path/usr/share/zoneinfo/$options{'tz'}" or die "No such timezone: $options{'tz'}!\n\n";

	cp("$cont_root_path/usr/share/zoneinfo/$options{'tz'}", "$cont_root_path/etc/localtime");
}

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	die "Strange, rare name... I don't know how to deal with it.\n" if ($options{'contname'} =~ m/^-.*/);

	GetOptions(\%options, 'ipaddr=s', 'hostname=s', 'userpasswd=s', 
		'nameserver=s', 'searchdomain=s', 'rootsz=s', 
		'netmask|mask=s', 'defgw|gw=s', 'dns=s', 'cpus=s', 'cpu-shares=s', 'mem=s', 'io=s', 
		'macaddr=s', 'autostart=s', 'tz|timezone=s', 'mtu=i', 'ifname=s');

	if (defined($options{'mem'})) {
		$options{'mem'} = $self->{'lxc'}->convert_size($options{'mem'}, "B");
	}

	# Dirty hack. set_macaddr used from create and should be able to work without --maccaddr option.
	$self->set_macaddr() if defined($options{'macaddr'});
	$self->set_ipaddr();
	$self->set_netmask();
	$self->set_defgw();
	$self->set_dns();
	$self->set_hostname();
	$self->set_searchdomain();
	$self->set_userpasswd();
	$self->set_rootsz();
	$self->set_autostart();
	$self->set_tz();
	$self->set_mtu();
	$self->set_ifname();
	$self->set_cgroup('cpu-shares', 'cpu.shares');
	$self->set_cgroup('cpus', 'cpuset.cpus');
	$self->set_cgroup('mem', 'memory.limit_in_bytes');
	$self->set_cgroup('io', 'blkio.weight');

	$config->change_hash(\%options, "$yaml_conf_dir/$options{'contname'}.yaml");

	return;
}

sub new
{
	my $class = shift;	
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$self->{'helper'} = LxctlHelpers::helper->new;

	$root_mount_path = $self->{'lxc'}->get_roots_path();
	$templates_path = $self->{'lxc'}->get_template_path();
	$yaml_conf_dir = $self->{'lxc'}->get_config_path();
	$lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();
	$vg = $self->{'lxc'}->get_vg();

	%options = @_;

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
