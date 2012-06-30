package Lxctl::create;

use strict;
use warnings;
use 5.010001;
use autodie qw(:all);

use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;

use Lxc::object;

use Lxctl::set;
use Lxctl::Helpers::config;
use Lxctl::Helpers::common;
use Lxctl::Helpers::generalValidators;
use Lxctl::Helpers::optionsValidator;
use Lxctl::Helpers::configValidator;
use Data::UUID;
use File::Path;

my $config = new Lxctl::Helpers::config;
my $helper = new Lxctl::Helpers::common;
my $generalValidator = new Lxctl::Helpers::generalValidators;
my $optionsValidator = new Lxctl::Helpers::optionsValidator;

my %options = ();
my %lxc_conf;

my @args;
my %conf;

my $root_mount_path;
my $templates_path;
my $yaml_conf_dir;
my $lxc_conf_dir;
my $vg;
my $lxc;

sub create_root
{
	my $self = shift;

	if ($options{'rootsz'} ne 'share') {
		if (lc($options{'roottype'}) eq 'lvm') {
			$helper->lvcreate($options{'contname'}, $lxc_conf{'lvm'}->{'VG'}, $options{'rootsz'});

			$helper->mkfs($options{'fs'}, "/dev/$lxc_conf{'lvm'}->{'VG'}/$options{'contname'}", $options{'mkfsopts'});
		} elsif (lc($options{'roottype'}) eq 'file') {
			print "Creating root in file: $root_mount_path/$options{'contname'}.raw\n";

			my $bs = 4096;
			my $count = $lxc->convert_size($options{'rootsz'}, 'b')/$bs;

			# Creating empty file of desired size. It's a bit slower then system dd, but still rather fast (around 10% slower then dd)
			system("dd if=/dev/zero of=$root_mount_path/$options{'contname'}.raw bs=$bs count=$count");

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
		system("mkdir -p $lxc_conf_dir/$options{'contname'}");
	}

	return;
}

sub check_create_options
{
	my $self = shift;
	$Getopt::Long::passthrough = 1;

	GetOptions(\%options, 'ipaddr=s', 'hostname=s', 'ostemplate=s', 
		'config=s', 'roottype=s', 'root=s', 'rootsz=s', 'netmask|mask=s',
		'defgw|gw=s', 'dns=s', 'macaddr=s', 'autostart=s', 'empty!',
		'save!', 'load=s', 'debug', 'searchdomain=s', 'tz=s',
		'fs=s', 'mkfsopts=s', 'mountoptions=s', 'mtu=i', 'userpasswd=s',
		'pkgopt=s', 'addpkg=s', 'ifname=s');

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

	$self->{'validator'}->act(\%options);

	if ($options{'empty'} == 0) {
		# TODO: Do we really need this warnings?
		if (!defined($options{'ipaddr'})) { 
			print "You did not specify IP address! Using default.\n";
		} elsif ($options{'ipaddr'} !~ m/\d+\.\d+\.\d+\.\d+\/\d+/ ) {
			if (defined($options{'netmask'})) {
				
			} else {
				print "You did not specify network mask! Using default.\n";
			}
		} else {
			
		}
		if (defined($options{'defgw'})) {
		} else {
			print "You did not specify default gateway! Using default.\n";
		}
		if (defined($options{'dns'})) {
		} else {
			print "You did not specify DNS! Using default.\n";
		}
	}

	my @domain_tokens = split(/\./, $options{'contname'});
	my $tmp_hostname = shift @domain_tokens;

	if ($options{'debug'}) {
		foreach my $key (sort keys %options) {
			print "options{$key} = $options{$key} \n";
		};
	}

	return $options{'uuid'};
}

sub check_existance
{
	my $self = shift;
	
	die "Container lxc conf directory $lxc_conf_dir/$options{'contname'} already exists!\n\n" 
		if -e "$lxc_conf_dir/$options{'contname'}";
	die "Container root directory $root_mount_path/$options{'contname'} already exists!\n\n"
		if -e "$root_mount_path/$options{'contname'}";
	die "Container root logical volume /dev/$lxc_conf{'lvm'}->{'VG'}/$options{'contname'} already exists!\n\n"
		if -e "/dev/$lxc_conf{'lvm'}->{'VG'}/$options{'contname'}";

	if ($options{'empty'} == 0) {
		if (! -e "$templates_path/$options{'ostemplate'}.tar.gz") {
			die "There is no such template: $templates_path/$options{'ostemplate'}.tar.gz\n\n";
		}
	}

	return;
}

sub deploy_template
{
	my $self = shift;

	my $template = "$templates_path/$options{'ostemplate'}.tar.gz";
	print "Deploying template: $template\n";

	system("tar xf $template -C $root_mount_path/$options{'contname'} 1>/dev/null");

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

sub act
{
	my $self = shift;
        my $conf_ref = shift;
        @args = @_;
        %conf = %{$conf_ref};

	$options{'contname'} = $args[0]
		or die "Name the container please!\n\n";

	if ( $options{'contname'} =~ m/^-/ ) {
		print "Command specified instead of container name, trying to parse...\n";
		undef($options{'contname'});
	} else {
		shift;
	}
	die "Trust me. You dont' want a container named 'lxctl'.\n\n" if ($options{'contname'} eq 'lxctl');

	$self->check_create_options();
	$self->check_existance();
	print "Creating container $options{'contname'}...\n";

	$self->create_root();

	my $fstab = "\
proc		$root_mount_path/$options{'contname'}/rootfs/proc		proc	nodev,noexec,nosuid	0 0
sysfs		$root_mount_path/$options{'contname'}/rootfs/sys		sysfs	defaults		0 0
";

	open my $fstab_file, '>', "$lxc_conf_dir/$options{'contname'}/fstab" or die "Can't create container's fstab";
	print $fstab_file $fstab;
	close($fstab_file);

	if (!defined($options{'ifname'})) {
		eval {
			$options{'ifname'} = $config->get_option_from_main('set', "IFNAME");
			1;
		} or do {
			$options{'ifname'} = "mac";
		};
	}

	my $setter = Lxctl::set->new(\%lxc_conf, \$self->{'validator'}, \%options);
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
		$setter->set_ifname();

		$self->deploy_packets();
	}
	$setter->set_autostart();

	$options{'api_ver'} = $config->get_api_ver();

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
	my $tmp = shift;
	%lxc_conf = %{$tmp};
	$tmp = shift;
	$self->{'validator'} = ${$tmp};
	$root_mount_path = $lxc_conf{'paths'}->{'ROOT_MOUNT_PATH'};
	$templates_path = $lxc_conf{'paths'}->{'TEMPLATE_PATH'};
	$yaml_conf_dir = $lxc_conf{'paths'}->{'YAML_CONFIG_PATH'};
	$lxc_conf_dir = $lxc_conf{'paths'}->{'LXC_CONF_DIR'};
	$vg = $lxc_conf{'lvm'}->{'VG'};

	$lxc = new Lxc::object;

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
