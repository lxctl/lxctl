package Lxctl::Helpers::configValidator;

# This is helper for validation container options. First, options from config
# and command line are merged, then they are validated to correctness and
# presence.

my %config;
my %options;

# Sets default value to given %config key.
sub set_default_value
{
	my ($class, $key, $value) = @_;

	if (!defined($options{$key})) {
		$options{$key} = $value;
	}
}

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
sub set_plain_defaults
{
	my $class = shift;

	set_default_value('api_ver', 0);
	set_default_value('autostart', 1);
	#set_default_value('debug', 0);
	#set_default_value('empty', 0);
	set_default_value('mkfsopts', $config{'fs'}->{'FS_OPTS'});
	set_default_value('mountoptions', $config{'fs'}->{'FS_MOUNT_OPTS'});
	set_default_value('ostemplate', $config{'os'}->{'OS_TEMPLATE'});
	set_default_value('rootsz', $config{'root'}->{'ROOT_SIZE'});
	set_default_value('roottype', $config{'root'}->{'ROOT_TYPE'});
	#set_default_value('save', 1);
	set_default_value('searchdomain', $config{'set'}->{'SEARCHDOMAIN'});
	set_default_value('hostname', $options{'contname'});
}

# contname: oxcd8o.dev.yandex.net
sub validate_contname
{
	my $class = shift;

	if (!defined($options{'contname'})) {
		die "Options error: 'contname': there is no container name in config file.\n";
	}
}

# uuid: 8291d9e6-b2f1-438e-be0b-391e75db1da5
# TODO: add uuid generation.
sub validate_uuid
{
	my $class = shift;

	if (!defined($options{'contname'})) {
		$options{'contname'} = 'blah-blah-blah';
	}
}

# config: '/var/lib/lxc/oxcd8o.dev.yandex.net'
sub validate_config
{
	my $class = shift;

	if (!defined($options{'config'})) {
		$options{'config'} = "$config{'paths'}->{'LXC_CONF_DIR'}/$options{'contname'}";
	}
	if (! -d "$options{'config'}") {
		die "Options error: 'config': $options{'config'} is not a directory.\n";
	} elsif (! -f "$options{'config'}/config") {
		die "Options error: 'config': $options{'config'}/config is not a file or does not exist.\n"
	}
}

# root: '/var/lxc/root/oxcd8o.dev.yandex.net'
sub validate_root 
{
	my $class = shift;

	if (!defined($options{'root'})) {
		$options{'root'} = "$config{'paths'}->{'ROOT_MOUNT_PATH'}/$options{'contname'}";
	}
	if (! -d "$options{'config'}") {
		die "Options error: 'root': $options{'root'} is not a directory.\n";
        } elsif (! -d "$options{'config'}/rootfs") {
		die "Options error: 'root': $options{'config'}/rootfs does not exist or not a directory.\n";
	}
}

# rootfs_mp:
#   from: '/dev/vg00/oxcd8o.dev.yandex.net'
#   fs: ext4
#   opts: defaults,barrier=0
#   to: '/var/lxc/root/oxcd8o.dev.yandex.net'
# TODO: roottype == file
sub validate_root_mp
{
	my $class = shift;

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

sub do
{
	my $class = shift;

	validate_contname;
	set_plain_defaults;
	validate_config;
	validate_uuid;
	validate_root;
	validate_root_mp;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	return $self;
}

1;

