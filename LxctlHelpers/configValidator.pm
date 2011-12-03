package LxctlHelpers::configValidator;

# Main purpouse of this helper is to ensure that there are all fields of main
# config filled. If some of fields (and even blocks) are missed, they will be
# created with default values.

my %config;

# lvm: LVM-related defaults.
#   VG: Name of the volume group, used by default.
sub validate_lvm
{
	my $class = shift;

	if (!defined($config{'lvm'})) {
		$config{'lvm'} = {};
	}

	if (!defined($config{'lvm'}->{'VG'})) {
		$config{'lvm'}->{'VG'} = 'vg00';
	}
}

# paths: Different paths to different files.
#   YAML_CONFIG_PATH: Default path to .yaml files of containers.
#   LXC_CONF_DIR: Default path to lxc containers' configs.
#   ROOT_MOUNT_PATH: Default paths to containers' roots. 
#   TEMPLATE_PATH: Default path to templates.
#   LXC_LOG_PATH: Default path to logs.
#   LXC_LOG_LEVEL: Default loglevel.
sub validate_paths
{
	my $class = shift;

	if (!defined($config{'paths'})) {
		$config{'paths'} = {};
	}

	if (!defined($config{'paths'}->{'YAML_CONFIG_PATH'})) {
		$config{'paths'}->{'YAML_CONFIG_PATH'} = '/etc/lxctl';
	}
	if (!defined($config{'paths'}->{'LXC_CONF_DIR'})) {
		$config{'paths'}->{'LXC_CONF_DIR'} = '/var/lib/lxc';
	}
	if (!defined($config{'paths'}->{'ROOT_MOUNT_PATH'})) {
		$config{'paths'}->{'ROOT_MOUNT_PATH'} = '/var/lxc/root';
	}
	if (!defined($config{'paths'}->{'TEMPLATE_PATH'})) {
		$config{'paths'}->{'TEMPLATE_PATH'} = '/var/lxc/templates';
	}
	if (!defined($config{'paths'}->{'LXC_LOG_PATH'})) {
		$config{'paths'}->{'LXC_LOG_PATH'} = '/var/log/lxc/%CONTNAME%.log';
	}
	if (!defined($config{'paths'}->{'LXC_LOG_LEVEL'})) {
		$config{'paths'}->{'LXC_LOG_LEVEL'} = 'DEBUG';
	}
}

# check: Different checks of conpatibility.
#   skip_kernel_config_check: Enable (or disable) check for lxc-related kernel features.
sub validate_check
{
	my $class = shift;

	if (!defined($config{'check'})) {
		$config{'check'} = {};
	}

	if (!defined($config{'check'}->{'skip_kernel_config_check'})) {
		$config{'check'}->{'skip_kernel_config_check'} = '1';
	}
}

#rsync: Rsync-related ortions.
#  RSYNC_OPTS: Default rsync options used at migration.
sub validate_rsync
{
	my $class = shift;

	if (!defined($config{'rsync'})) {
		$config{'rsync'} = {};
	}

	if (!defined($config{'rsync'}->{'RSYNC_OPTS'})) {
		$config{'rsync'}->{'RSYNC_OPTS'} = "-aH --delete --numeric-ids --exclude 'proc/*' --exclude 'sys/*' -e ssh";
	}
}

#root: Different parameters of containers' roots.
#  ROOT_SIZE: Default root size (only for LVMs).
#  ROOT_TYPE: Default root type.
sub validate_root
{
	my $class = shift;

	if (!defined($config{'root'})) {
		$config{'root'} = {};
	}

	if (!defined($config{'root'}->{'ROOT_SIZE'})) {
		$config{'root'}->{'ROOT_SIZE'} = '50G';
	}
	if (!defined($config{'root'}->{'ROOT_TYPE'})) {
		$config{'root'}->{'ROOT_TYPE'} = 'lvm';
	}
}

#fs: Default filesystem options (only for LVMs).
#  FS: Default filesystem.
#  FS_OPTS: Default filesystem create options.
#  FS_MOUNT_OPTS: Default filesystem mount options.
sub validate_fs
{
	my $class = shift;

	if (!defined($config{'fs'})) {
		$config{'fs'} = {};
	}

	if (!defined($config{'fs'}->{'FS'})) {
		$config{'fs'}->{'FS'} = 'ext4';
	}
	if (!defined($config{'fs'}->{'FS_OPTS'})) {
		$config{'fs'}->{'FS_OPTS'} = '-b 4096';
	}
	if (!defined($config{'fs'}->{'FS_MOUNT_OPTS'})) {
		$config{'fs'}->{'FS_MOUNT_OPTS'} = 'defaults,barrier=0';
	}
}

#os: Templates' settings.
#  OS_TEMPLATE: Default template.
sub validate_os
{
	my $class = shift;

	if (!defined($config{'os'})) {
		$config{'os'} = {};
	}

	if (!defined($config{'os'}->{'OS_TEMPLATE'})) {
		$config{'os'}->{'OS_TEMPLATE'} = 'ubuntu-10.04-amd64';
	}
}

#set: Different system settings.
#  SEARCHDOMAIN: Default 'search' parameter of resolv.conf.
#  IFNAME: Default method of generatinf veth interface name on host-system.
sub validate_set
{
	my $class = shift;

	if (!defined($config{'set'})) {
		$config{'set'} = {};
	}

	if (!defined($config{'set'}->{'SEARCHDOMAIN'})) {
		$config{'set'}->{'SEARCHDOMAIN'} = 'ru';
	}
	if (!defined($config{'set'}->{'IFNAME'})) {
		$config{'set'}->{'IFNAME'} = 'ip';
	}
}

#list: Different options of container listung.
#  COLUMNS: Default columns for `lxctl list` output.
sub validate_list
{
	my $class = shift;

	if (!defined($config{'list'})) {
		$config{'list'} = {};
	}

	if (!defined($config{'list'}->{'COLUMNS'})) {
		$config{'list'}->{'COLUMNS'} = 'name,disk_free_mb,status,ip,hostname';
	}
}

# Get hash and return it validated.
sub validate
{
	my $class;
	($class, %config) = @_;

	validate_lvm;
	validate_paths;
	validate_check;
	validate_rsync;
	validate_root;
	validate_fs;
	validate_os;
	validate_set;
	validate_list;

	return %config;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	return $self;
}

1;
