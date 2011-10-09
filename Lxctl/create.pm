package Lxctl::create;

use strict;
use warnings;
use autodie qw(:all);

use Getopt::Long qw(GetOptionsFromArray);

use Lxc::object;

use Lxctl::set;
use LxctlHelpers::config;
use LxctlHelpers::helper;
use Data::UUID;
use File::Path;

my $config = new LxctlHelpers::config;
my $helper = new LxctlHelpers::helper;

my %options = ();

my $lxc;
my $yaml_conf_dir;
my $lxc_conf_dir;
my $root_mount_path;
my $templates_path;
my $vg;

my @args;

sub check_existance
{
	my $self = shift;

	die "Container lxc conf directory $lxc_conf_dir/$options{'contname'} already exists!\n\n" 
		if -e "$lxc_conf_dir/$options{'contname'}";
	die "Container root directory $root_mount_path/$options{'contname'} already exists!\n\n"
		if -e "$root_mount_path/$options{'contname'}";
	die "Container root logical volume /dev/$vg/$options{'contname'} already exists!\n\n"
		if -e "/dev/$vg/$options{'contname'}";

	if ($options{'empty'} == 0) {
		if (! -e "$templates_path/$options{'ostemplate'}.tar.gz") {
			die "There is no such template: $templates_path/$options{'ostemplate'}.tar.gz\n\n";
		}
	}

	return;
}

sub create_root
{
	my $self = shift;

	if ($options{'rootsz'} ne 'share') {
		if (lc($options{'roottype'}) eq 'lvm') {
			$helper->lvcreate($options{'contname'}, $vg, $options{'rootsz'});

			$helper->mkfs($options{'fs'}, "/dev/$vg/$options{'contname'}",   $options{'mkfsopts'});
		} elsif (lc($options{'roottype'}) eq 'file') {
			print "Creating root in file: $root_mount_path/$options{'contname'}.raw\n";

			my $bs = 4096;
			my $count = $lxc->convert_size($options{'rootsz'}, 'b')/$bs;

			# Creating empty file of desired size. It's a bit slower then system dd, but still rather fast (around 10% slower then dd)
			open my $raw_file, '>' , "$root_mount_path/$options{'contname'}.raw";
			print $raw_file "\0" x($count*$bs);
			close ($raw_file);

			$helper->mkfs($options{'fs'}, "$root_mount_path/$options{'contname'}.raw", $options{'mkfsopts'});
		}
	}

	print "Creating directory: $root_mount_path/$options{'contname'}\n";

	mkpath("$root_mount_path/$options{'contname'}/rootfs");

	if ($options{'rootsz'} ne 'share') {
		print "Fixing fstab...\n";

		my $what_to_mount = "";
		my $additional_opts = "";
		if (lc($options{'roottype'}) eq 'lvm') {
			$what_to_mount = "/dev/$vg/$options{'contname'}";
		} elsif (lc($options{'roottype'}) eq 'file') {
			$what_to_mount = "$root_mount_path/$options{'contname'}.raw";
			$additional_opts=",loop";
		}
		# TODO: We disscused and decieded to keep all mounts in array of hashes in yaml file and apply on start.
		my %root_mp = (
			'from' => "$what_to_mount",
			'to' => "$root_mount_path/$options{'contname'}",
			'fs' => "$options{'fs'}",
			'opts' => "$options{'mountoptions'}$additional_opts",
			);

		$options{'rootfs_mp'} = \%root_mp;
		print "Mounting FS...\n";

		system("mount -t $root_mp{'fs'} -o $root_mp{'opts'} $root_mp{'from'} $root_mp{'to'} 1>/dev/null");
	}

	return;
}

sub check_create_options
{
	my $self = shift;
	$Getopt::Long::passthrough = 1;

	GetOptions(\%options, 'ipaddr=s', 'hostname=s', 'ostemplate=s', 
		'config=s', 'roottype=s', 'root=s', 'pkgset=s', 'rootsz=s', 'netmask|mask=s',
		'defgw|gw=s', 'dns=s', 'macaddr=s', 'autostart=s', 'empty!',
		'save!', 'load=s', 'debug', 'searchdomain=s', 'tz=s',
		'fs=s', 'mkfsopts=s', 'mountoptions=s', 'mtu=i', 'userpasswd=s',
		'pkgopt=s', 'addpkg=s');

	if (defined($options{'load'})) {
		if ( ! -f $options{'load'}) {
			print "Cannot find config-file $options{'load'}, ignoring...\n";
			last;
		};

		my $result = $config->load_file($options{'load'});
		my %opts_new = %$result;

		foreach my $key (sort keys %options) {
			$opts_new{$key} = $options{$key};
		};

		%options = %opts_new;
	}

	if (!defined($options{'contname'})) {
		die "No container name specified\n\n";
	}

	my $ug = new Data::UUID;
	$options{'uuid'} = $ug->create_str();

	$options{'ostemplate'} ||= $config->get_option_from_main('os', 'OS_TEMPLATE');
	$options{'config'} ||= "$lxc_conf_dir/$options{'contname'}";
	$options{'root'} ||= "$root_mount_path/$options{'contname'}";
	$options{'rootsz'} ||= $config->get_option_from_main('root', 'ROOT_SIZE');
	$options{'autostart'} ||= "1";
	$options{'roottype'} ||= $config->get_option_from_main('root', 'ROOT_TYPE');

	if (!defined($options{'empty'})) {
		$options{'empty'} = 0;
	}

	$options{'debug'} ||= 0;

	if (!defined($options{'save'})) {
		$options{'save'} = 1;
	}

	if ($options{'empty'} == 0) {
		$options{'ipaddr'} || print "You did not specify IP address! Using default.\n";
		if (! $options{'ipaddr'} =~ m/\d+\.\d+\.\d+\.\d+\/\d+/ ) {
			$options{'netmask'} || print "You did not specify network mask! Using default.\n";
		}
		$options{'defgw'} || print "You did not specify default gateway! Using default.\n";
		$options{'dns'} || print "You did not specify DNS! Using default.\n";
	}

	my @domain_tokens = split(/\./, $options{'contname'});
	my $tmp_hostname = shift @domain_tokens;
	$options{'hostname'} ||= $tmp_hostname;
	$options{'searchdomain'} ||= join '.', @domain_tokens;
	if ($options{'searchdomain'} eq "") {
		$options{'searchdomain'} = $config->get_option_from_main('set', 'SEARCHDOMAIN');
	}

	if ($options{'debug'}) {
		foreach my $key (sort keys %options) {
			print "options{$key} = $options{$key} \n";
		};
	}
	$options{'fs'} ||= $config->get_option_from_main('fs', 'FS');
	$options{'mkfsopts'} ||= $config->get_option_from_main('fs', 'FS_OPTS');
	$options{'mountoptions'} ||= $config->get_option_from_main('fs', 'FS_MOUNT_OPTS');

	return $options{'uuid'};
}

sub deploy_template
{
	my $self = shift;

	my $template = "$templates_path/$options{'ostemplate'}.tar.gz";
	print "Deploying template: $template\n";

	system("tar xf $template -C $root_mount_path/$options{'contname'} 1>/dev/null");

	return;
}

sub create_lxc_conf
{
	my $self = shift;

	print "Creating lxc configuration file: $lxc_conf_dir/$options{'contname'}/config\n";	

	mkpath("$lxc_conf_dir/$options{'contname'}");

	my $conf = "\
lxc.utsname = $options{'contname'}

lxc.tty = 4
lxc.pts = 1024
lxc.rootfs = $root_mount_path/$options{'contname'}/rootfs
lxc.mount  = $lxc_conf_dir/$options{'contname'}/fstab

lxc.cgroup.devices.deny = a
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = br0
lxc.network.name = eth0
lxc.network.mtu = 1500
";

	my $fstab = "\
proc			$root_mount_path/$options{'contname'}/rootfs/proc		 proc	nodev,noexec,nosuid 0 0
sysfs		   $root_mount_path/$options{'contname'}/rootfs/sys		  sysfs defaults  0 0
";

	open my $config_file, '>', "$lxc_conf_dir/$options{'contname'}/config";
	print $config_file $conf;
	close($config_file);

	open my $fstab_file, '>', "$lxc_conf_dir/$options{'contname'}/fstab";
	print $fstab_file $fstab;
	close($fstab_file);

	return;
}

sub create_ssh_keys
{
	my $self = shift;

	print "Regenerating SSH keys...\n";

	eval {
		system("rm $root_mount_path/$options{'contname'}/rootfs/etc/ssh/ssh_host_*");
		1;
	} or do {
		print "Failed to delete old ssh keys!\n\n";
	};

	system("ssh-keygen -q -t rsa -f $root_mount_path/$options{'contname'}/rootfs/etc/ssh/ssh_host_rsa_key -N ''");
	system("ssh-keygen -q -t dsa -f $root_mount_path/$options{'contname'}/rootfs/etc/ssh/ssh_host_dsa_key -N ''");
}

sub deploy_packets
{
	my $self = shift;

	defined($options{'addpkg'}) or return;
	$options{'pkgopt'} ||= "";

	$options{'addpkg'} =~ s/,/ /g;

	print "Adding packages: $options{'addpkg'}\n";

	## Deb only
	system("chroot $root_mount_path/$options{'contname'}/rootfs/ apt-get $options{'pkgopt'} install $options{'addpkg'}");

	return;
}


sub do
{
	my ($self) = shift;

	$options{'contname'} = $_[0]
		or die "Name the container please!\n\n";

	if ( $options{'contname'} =~ m/^-/ ) {
		print "Command specified instead of container name, trying to parse...\n";
		undef($options{'contname'});
	} else {
		shift;
	}

	$self->check_create_options();
	$self->check_existance();
	print "Creating container $options{'contname'}...\n";
	$self->create_root();
	$self->create_lxc_conf();

	my $setter = Lxctl::set->new(%options);
	$setter->set_macaddr();

	if ($options{'empty'} == 0) {
		$self->deploy_template();
		$self->create_ssh_keys();

		$setter->set_ipaddr();
		$setter->set_netmask();
		$setter->set_defgw();
		$setter->set_dns();
		$setter->set_hostname();
		$setter->set_searchdomain();
		$setter->set_tz();
		$setter->set_mtu();
		$setter->set_userpasswd();

		$self->deploy_packets();
	}

	$setter->set_autostart();

	$options{'save'} && $config->save_hash(\%options, "$yaml_conf_dir/$options{'contname'}.yaml");

	print "Container $options{'contname'}' created.\n";

	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$lxc = new Lxc::object;

	$root_mount_path = $lxc->get_roots_path();
	$templates_path = $lxc->get_template_path();
	$yaml_conf_dir = $lxc->get_config_path();
	$lxc_conf_dir = $lxc->get_lxc_conf_dir();
	$vg = $lxc->get_vg();

	return $self;
}

1;
__END__

=head1 NAME

Lxctl::create

=head1 SYNOPSIS

Basic create command. Should be sufficient for all needs

=head1 DESCRIPTION

Basic create command. Should be sufficient for all needs

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
