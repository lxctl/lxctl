package Lxctl::Helpers::optionsValidator;


=pod
=head1 NAME
Lxctl::Helpers::optionsValidators - config class.

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This is helper for validation container options. First, options from config
and command line are merged, then they are validated to correctness and
presence.

=head1 METHODS
=cut

use Lxctl::Helpers::generalValidators;
use Data::UUID;
use Data::Dumper;

my %config;
my %options;
my %append;
my %generalOpts = ();
my $debug = 1;

=pod
# Sets default value to given %config key.
=cut
sub set_default_value
{
	my ($self, $key, $value) = @_;

	if (!defined($options{$key})) {
		$options{$key} = $value;
	}
}

=pod
# Initialize configuration options, wich don't require some complex logic.
# I've commented out options, which shoul not be written to config because
# of their lifetime - single session. They should be added from command line
# options. And this is a TODO ;)
#
# api_ver: 1
# autostart: 1
## debug: 0
## empty: 0
# mkfsopts: '-b 4096 -E stride=16,stripe-width=32'
# mountoptions: defaults,barrier=0
# ostemplate: ubuntu-10.04-amd64
# rootsz: 50G
# roottype: lvm
## save: 1
# searchdomain: dev.yandex.net
# hostname: oxcd8o
=cut
sub set_plain_defaults
{
	my $self = shift;

	$self->{'validator'}->validate(\%options, 'api_ver', 'int', 0);
	$self->{'validator'}->validate(\%options, 'autostart', 'int', 1);
	$self->{'validator'}->validate(\%options, 'debug', 'int', 0);
	$self->{'validator'}->validate(\%options, 'empty', 'int', 0);
	$self->{'validator'}->validate(\%options, 'save', 'int', 1);
	$self->{'validator'}->validate(\%options, 'contname', 'str', undef);
	$self->{'validator'}->validate(\%options, 'mkfsopts', 'str', $config{'fs'}->{'FS_OPTS'});
	$self->{'validator'}->validate(\%options, 'mountoptions', 'str', $config{'fs'}->{'FS_MOUNT_OPTS'});
	$self->{'validator'}->validate(\%options, 'ostemplate', 'str', $config{'os'}->{'OS_TEMPLATE'});
	$self->{'validator'}->validate(\%options, 'rootsz', 'str', $config{'root'}->{'ROOT_SIZE'});
	$self->{'validator'}->validate(\%options, 'roottype', 'str', $config{'root'}->{'ROOT_TYPE'});
	$self->{'validator'}->validate(\%options, 'searchdomain', 'str', $config{'set'}->{'SEARCHDOMAIN'});
	$self->{'validator'}->validate(\%options, 'hostname', 'str', $options{'contname'});
}

=pod
# contname: oxcd8o.dev.yandex.net
=cut
sub validate_contname
{
	my $self = shift;

	if (!defined($options{'contname'})) {
		die "Options error: 'contname': there is no container name in config file.\n";
	}
}

=pod
# uuid: 8291d9e6-b2f1-438e-be0b-391e75db1da5
=cut
sub validate_uuid
{
	my $self = shift;

	if (!defined($options{'uuid'})) {
		my $ug = new Data::UUID;
		$options{'uuid'} = $ug->create_str();
	}
}

=pod
# config: '/var/lib/lxc/oxcd8o.dev.yandex.net'
=cut
sub validate_config
{
	my $self = shift;

	if (!defined($options{'config'})) {
		$options{'config'} = "$config{'paths'}->{'LXC_CONF_DIR'}/$options{'contname'}";
	}
	if (! -d "$options{'config'}") {
		die "Options error: 'config': $options{'config'} is not a directory.\n";
	} elsif (! -f "$options{'config'}/config") {
		die "Options error: 'config': $options{'config'}/config is not a file or does not exist.\n"
	}
}

=pod
# root: '/var/lxc/root/oxcd8o.dev.yandex.net'
=cut
sub validate_root 
{
	my $self = shift;

	if (!defined($options{'root'})) {
		$options{'root'} = "$config{'paths'}->{'ROOT_MOUNT_PATH'}/$options{'contname'}";
	}
	if (! -d "$options{'config'}") {
		die "Options error: 'root': $options{'root'} is not a directory.\n";
        } elsif (! -d "$options{'config'}/rootfs") {
		die "Options error: 'root': $options{'config'}/rootfs does not exist or not a directory.\n";
	}
}

=pod
# rootfs_mp:
#   from: '/dev/vg00/oxcd8o.dev.yandex.net'
#   fs: ext4
#   opts: defaults,barrier=0
#   to: '/var/lxc/root/oxcd8o.dev.yandex.net'
# TODO: roottype == file
=cut
sub validate_root_mp
{
	my $self = shift;

	if (!defined($options{'root_mp'}) && $options{'roottype'} ne 'share') {
		$options{'root_mp'} = {};
	}
	if (!defined($options{'root_mp'}->{'from'}) && $options{'roottype'} ne 'share') {
		if ($options{'roottype'} eq 'lvm') {
			$options{'root_mp'}->{'from'} = "/dev/$config{'lvm'}->{'VG'}/$options{'contname'}";
		} else {
			die "Options error: 'root_mp/from': Don't know what to mount as root.\n";
		}
	}
	if (!defined($options{'root_mp'}->{'fs'}) && $options{'roottype'} ne 'share') {
		if ($options{'roottype'} eq 'lvm') {
			$options{'root_mp'}->{'fs'} = $config{'fs'}->{'FS'};
		} else {
			die "Options error: 'root_mp/fs': Don't know what filesystem should be mounted as root.\n";
		}
	}
	if (!defined($options{'root_mp'}->{'opts'}) && $options{'roottype'} ne 'share') {
		if ($options{'roottype'} eq 'lvm') {
			$options{'root_mp'}->{'opts'} = $config{'fs'}->{'FS_OPTS'};
		} else {
			die "Options error: 'root_mp/fs': Don't know with what options root should be mounted.\n";
		}
	}
	if ($options{'roottype'} eq 'lvm' && ! -e "$options{'root_mp'}->{'from'}") {
		die "Options error: 'root_mp/from': $options{'root_mp'}->{'from'} does not exist.\n";
        }
}

=pod
validate_hash(\%what, \%parameters)
=cut
sub validate_hash
{
	my ($self, $what, $params) = @_;
	print "validate_hash\n" if ($debug == 1);
	my %parameters = %{$params};

	for my $key (sort keys %parameters) {
		print " DEBUG: validate_hash: $key\n" if ($debug == 1);
		next if (!defined($params->{"$key"}));
		if (ref($params->{"$key"}) eq "HASH") {
			if (!defined($what->{"$key"})) {
				$what->{"$key"} = {};
			}
			print "  DEBUG: validating: $key with $parameters{$key}\n" if ($debug == 1);
			$self->validate_hash($what->{"$key"}, $parameters{"$key"});
			next;
		} elsif (ref($params->{"$key"}) ne "ARRAY") {
			print "=====================BEGIN OF DATA DUMP=====================\n";
			print "BUG: Unknown type in 'sub validate_hash' reference on key: $key. Please, send following dump to developers:\n\n";
			print Dumper(%parameters);
			die "======================END OF DATA DUMP======================\n";
		}
		my @val = @{$params->{"$key"}};
		$self->{'validator'}->validate($what, "$key", $val[0], $val[1], @{$val[2]});
	}
}

=pod
act
=cut
sub act
{
	my ($self, $conf, $opt, $apnd) = @_;
	my %conf_dummy;
	%config = %{$conf} if defined($conf);
	%options = %{$opt} if defined($opt);
	%append = %{$apnd} if defined($appnd);
	
	%configOpts = (
		'os' => {
			'CONFIG_DIR' => ['dir', '/var/lxc/conf'],
			'OS_TEMPLATE' => ['str', 'ubuntu-10.04-amd64'],
			},
		'root' => {
			'ROOT_TYPE' => ['enum', 'lvm', ['lvm', 'file', 'share']],
			'MOUNT_PATH' => ['dir', '/var/lxc/root'],
			'ROOT_SIZE' => ['size', '10G'],
			},
		'set' => {
			'SEARCHDOMAIN' => ['str', 'local'],
			},
		'fs' => {
			'FS_OPTS' => ['str', ''],
			'FS_MOUNT_OPTS' => ['str', 'noatime'],
			},
		'lvm' => ['str', 'vg00'],
		);
	$self->validate_hash(\%config, \%configOpts);
	print Dumper(%config);

	die "No container name specified\n" if (!defined($options{'contname'}));

	%generalOpts = (
			'api_ver' => ['int', 0],
			'autostart' =>  ['int', 1],
			'debug' =>  ['int', 0],
			'empty' =>  ['int', 0],
			'save' =>  ['int', 1],
			'contname' =>  ['str', undef],
			'mkfsopts' =>  ['str', $config{'fs'}->{'FS_OPTS'}],
			'mountoptions' =>  ['str', $config{'fs'}->{'FS_MOUNT_OPTS'}],
			'ostemplate' =>  ['str', $config{'os'}->{'OS_TEMPLATE'}],
			'config' => ['dir', "$config{'os'}->{'CONFIG_DIR'}/$options{'contname'}", 0],
			'root' => ['dir', "$config{'root'}->{'MOUNT_PATH'}/$options{'contname'}", 0],
			'rootsz' =>  ['str', $config{'root'}->{'ROOT_SIZE'}],
			'roottype' =>  ['enum', $config{'root'}->{'ROOT_TYPE'}, ['lvm', 'file', 'share']],
			'searchdomain' =>  ['str', $config{'set'}->{'SEARCHDOMAIN'}],
			'hostname' =>  ['str', $options{'contname'}],
	);
	if (%append) {
		%generalOpts = (%generalOpts, %append);
	}

	$self->validate_hash(\%options, \%generalOpts);
	die "OKOKOK\n";
	
	validate_uuid;
	validate_root;
	validate_root_mp;
}

sub new
{
	my $parent = shift;
	my $self = {};
	my $debug_tmp = shift;
	if (defined($debug_tmp)) {
		$debug = $debug_tmp;
	}
	bless $self, $parent;
	$self->{'validator'} = new Lxctl::Helpers::generalValidators;

	return $self;
}

1;

