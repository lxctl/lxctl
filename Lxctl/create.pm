package Lxctl::create;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;

use Lxctl::set;
use Lxctl::_config;


my $config = new Lxctl::_config;

my %options = ();

sub check_existance
{
	my $self = shift;

	die "Container lxc conf directory $self->{'LXC_CONF_DIR'}/$options{'contname'} already exists!\n\n" 
		if -e "$self->{'LXC_CONF_DIR'}/$options{'contname'}";
	die "Container root directory $self->{'ROOTS_PATH'}/$options{'contname'} already exists!\n\n"
		if -e "$self->{'ROOTS_PATH'}/$options{'contname'}";
	die "Container root logical volume /dev/$self->{'VG'}/$options{'contname'} already exists!\n\n"
		if -e "/dev/$self->{'VG'}/$options{'contname'}";

	if ($options{'empty'} == 0) {
		if (! -e "$self->{'TEMPLATES_PATH'}/$options{'ostemplate'}.tar.gz") {
			die "Ther is no such template: $self->{'TEMPLATES_PATH'}/$options{'ostemplate'}.tar.gz\n\n";
		}
	}

	return;
}

sub create_root
{
	my $self = shift;

	if ($options{'rootsz'} ne 'share') {
		if (lc($options{'roottype'}) eq 'lvm') {
			print "Creating root logical volume: /dev/$self->{'VG'}/$options{'contname'}\n";

			die "Failed to create logical volume $options{'contname'}!\n\n"
					if system("lvcreate -L $options{'rootsz'} -n $options{'contname'} $self->{'VG'} 1>/dev/null");

			my $msg = "";
			if ($options{'mkfsopts'} ne "") {
				$msg = " with options $options{'mkfsopts'}";
			}
			print "Creating $options{'fs'} FS$msg: /dev/$self->{'VG'}/$options{'contname'}\n";

			die "Failed to create FS for $options{'contname'}!\n\n"
				if system("mkfs.$options{'fs'} /dev/$self->{'VG'}/$options{'contname'} $options{'mkfsopts'} 1>/dev/null");
		} elsif (lc($options{'roottype'}) eq 'file') {
			print "Creating root in file: $self->{'ROOTS_PATH'}/$options{'contname'}.raw\n";

			my $bs = 4096;
			my $count = $self->{'lxc'}->convert_size($options{'rootsz'}, 'b')/$bs;

			die "Failed to create file $options{'contname'}.raw!\n\n"
				if system("dd if=/dev/zero of=\"$self->{'ROOTS_PATH'}/$options{'contname'}.raw\" bs=$bs count=$count");

			my $msg = "";
			if ($options{'mkfsopts'} ne "") {
				$msg = " with options $options{'mkfsopts'}";
			}
			print "Creating $options{'fs'} FS$msg: $self->{'ROOTS_PATH'}/$options{'contname'}.raw\n";

			die "Failed to create FS for $options{'contname'}!\n\n"
				if system("yes | mkfs.$options{'fs'} $self->{'ROOTS_PATH'}/$options{'contname'}.raw $options{'mkfsopts'} 1>/dev/null");
		}
	}

	print "Creating directory: $self->{'ROOTS_PATH'}/$options{'contname'}\n";

	die "Failed to create directory $self->{'ROOTS_PATH'}/$options{'contname'}!\n\n"
		if system("mkdir -p $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs 1>/dev/null");

	if ($options{'rootsz'} ne 'share') {
		print "Fixing fstab...\n";

		my $what_to_mount = "";
		my $additional_opts = "";
		if (lc($options{'roottype'}) eq 'lvm') {
			$what_to_mount = "/dev/$self->{'VG'}/$options{'contname'}";
		} elsif (lc($options{'roottype'}) eq 'file') {
			$what_to_mount = "$self->{'ROOTS_PATH'}/$options{'contname'}.raw";
			$additional_opts=",loop";
		}
		die "Failed to add fstab entry for $options{'contname'}!\n\n"
			if system("echo '$what_to_mount $self->{'ROOTS_PATH'}/$options{'contname'} $options{'fs'} $options{'mountoptions'}$additional_opts 0 0' >> /etc/fstab");

		print "Mounting FS...\n";

		die "Failed to mount FS for $options{'contname'}!\n\n"
			if system("mount $self->{'ROOTS_PATH'}/$options{'contname'} 1>/dev/null");
	}

	return;
}

sub check_create_options
{
	my $self = shift;

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
	};

	if (!defined($options{'contname'})) {
		die "No container name specified\n\n";
	}

	$options{'ostemplate'} ||= "lucid_amd64";
	$options{'config'} ||= "$self->{'LXC_CONF_DIR'}/$options{'contname'}";
	$options{'root'} ||= "$self->{'ROOTS_PATH'}/$options{'contname'}";
	$options{'rootsz'} ||= "10G";
	$options{'autostart'} ||= "1";
	$options{'roottype'} ||= "lvm";
	
	if (!defined($options{'empty'})) {
		$options{'empty'} = 0;
	}

	$options{'debug'} ||= 0;

	if (!defined($options{'save'})) {
		$options{'save'} = 1;
	}

	if ($options{'empty'} == 0) {
		$options{'ipaddr'} || print "You did not specify IP address! Using default.\n";
		$options{'netmask'} || print "You did not specify network mask! Using default.\n";
		$options{'defgw'} || print "You did not specify default gateway! Using default.\n";
		$options{'dns'} || print "You did not specify DNS! Using default.\n";
	};

	my @domain_tokens = split(/\./, $options{'contname'});
	$options{'hostname'} ||= shift @domain_tokens;
	$options{'searchdomain'} ||= join '.', @domain_tokens;

	if ($options{'debug'}) {
		foreach my $key (sort keys %options) {
			print "options{$key} = $options{$key} \n";
		};
	}
	$options{'fs'} ||= "ext4";
	$options{'mkfsopts'} ||= "";
	
	if ($options{'fs'} eq "ext4") {
		$options{'mountoptions'} ||= "defaults,noatime";
	} else {
		$options{'mountoptions'} ||= "defaults";
	}

	return;
}

sub deploy_template
{
	my $self = shift;

	my $template = "$self->{'TEMPLATES_PATH'}/$options{'ostemplate'}.tar.gz";
	print "Deploying template: $template\n";

	die "Failed to untar template!\n\n"
		if system("tar xf $template -C $self->{'ROOTS_PATH'}/$options{'contname'} 1>/dev/null");

	return;
}

sub create_lxc_conf
{
	my $self = shift;

	print "Creating lxc configuration file: $self->{'LXC_CONF_DIR'}/$options{'contname'}/config\n";	

	die "Failed to create directory $self->{'LXC_CONF_DIR'}/$options{'contname'}!\n\n"
		if system("mkdir -p $self->{'LXC_CONF_DIR'}/$options{'contname'} 1>/dev/null");

	my $conf = "\
lxc.utsname = $options{'contname'}

lxc.tty = 4
lxc.pts = 1024
lxc.rootfs = $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs
lxc.mount  = $self->{'LXC_CONF_DIR'}/$options{'contname'}/fstab

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
proc            $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/proc         proc    nodev,noexec,nosuid 0 0
sysfs           $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/sys          sysfs defaults  0 0
";

	open my $config_file, '>', "$self->{'LXC_CONF_DIR'}/$options{'contname'}/config" or
		die "Failed to create $self->{'LXC_CONF_DIR'}/$options{'contname'}/config!\n\n";
	print $config_file $conf;
	close($config_file);

	open my $fstab_file, '>', "$self->{'LXC_CONF_DIR'}/$options{'contname'}/fstab" or
		die "Failed to create $self->{'LXC_CONF_DIR'}/$options{'contname'}/fstab!\n\n";
	print $fstab_file $fstab;
	close($fstab_file);

	return;
}

sub create_ssh_keys
{
	my $self = shift;

	print "Regenerating SSH keys...\n";

	print "Failed to delete old ssh keys!\n\n"
		if system("rm $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/ssh/ssh_host_*");

	die "Failed to generete RSA key!\n\n"
		if system("ssh-keygen -q -t rsa -f $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/ssh/ssh_host_rsa_key -N ''");
	die "Failed to generete DSA key!\n\n"
		if system("ssh-keygen -q -t dsa -f $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/etc/ssh/ssh_host_dsa_key -N ''");
}

sub deploy_packets
{
        my $self = shift;

        defined($options{'addpkg'}) or return;
	$options{'pkgopt'} ||= "";

	$options{'addpkg'} =~ s/,/ /g;

        print "Adding packages: $options{'addpkg'}\n";

        die "Failed to install packets!\n\n"
                if system("chroot $self->{'ROOTS_PATH'}/$options{'contname'}/rootfs/ apt-get $options{'pkgopt'} install $options{'addpkg'}");

        return;
}


sub do
{
	my $self = shift;

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

	$options{'save'} && $config->save_hash(\%options, "$self->{'CONFIG_PATH'}/$options{'contname'}.yaml");

	print "\nDone! Run 'lxctl start $options{'contname'}' to try it now.\n";

	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;

	$self->{'ROOTS_PATH'} = $self->{'lxc'}->get_roots_path();
	$self->{'TEMPLATES_PATH'} = $self->{'lxc'}->get_template_path();
	$self->{'CONFIG_PATH'} = $self->{'lxc'}->get_config_path();
	$self->{'LXC_CONF_DIR'} = $self->{'lxc'}->get_lxc_conf_dir();
	$self->{'VG'} = $self->{'lxc'}->get_vg();


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
