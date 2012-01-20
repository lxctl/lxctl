package Lxctl::Helpers::configValidator;

use Lxctl::Helpers::generalValidators;

# Main purpouse of this helper is to ensure that there are all fields of main
# config filled. If some of fields (and even blocks) are missed, they will be
# created with default values.

my %config;

# paths: Different paths to different files.
#   yaml: Default path to .yaml files of containers.
#   lxc: Default path to lxc containers' configs.
#   root: Default paths to containers' roots. 
#   template: Default path to templates.
#   module: Additional modules path.
sub validate_paths
{
	my $self = shift;

	if (!defined($config{'paths'})) {
		$config{'paths'} = {};
	}

	eval {
		$self->{'valid'}->defaultDir($config{'paths'}->{'yaml'}, '/etc/lxctl');
		$self->{'valid'}->defaultDir($config{'paths'}->{'lxc'}, '/var/lib/lxc');
		$self->{'valid'}->defaultDir($config{'paths'}->{'root'}, '/var/lxc/root');
		$self->{'valid'}->defaultDir($config{'paths'}->{'template'}, '/var/lxc/templates');
		$self->{'valid'}->defaultDir($config{'paths'}->{'module'}, '.');
	}
}

# log: Different log settings.
#   level: Default loglevel.
#   path: Default path to logs.
sub validate_log
{
	my $class = shift;

	if (!defined($config{'log'})) {
		$config{'log'} = {};
	}

	eval {
		$self->{'valid'}->defaultEnum($config{'log'}->{'level'}, 'DEBUG', ('DEBUG', 'INFO', 'WARN'));
		$self->{'valid'}->defaultDir($config{'log'}->{'path'}, '/var/log/lxc');
	}
}

# check: Different checks of compatibility.
#   kernel_config: Enable (or disable) check for lxc-related kernel features.
sub validate_check
{
	my $class = shift;

	if (!defined($config{'check'})) {
		$config{'check'} = {};
	}

	eval {
		$self->{'valid'}->defaultEnum($config{'check'}->{'kernel_config'}, '1', ('1', '2'));
	}
}

#rsync: Rsync-related ortions.
#  opts: Default rsync options used at migration.
sub validate_rsync
{
	my $class = shift;

	if (!defined($config{'rsync'})) {
		$config{'rsync'} = {};
	}

	eval {
		$self->{'valid'}->defaultString($config{'rsync'}->{'opts_first'}, "-aH --delete --numeric-ids --exclude 'proc/*' --exclude 'sys/*' -e ssh");
		$self->{'valid'}->defaultString($config{'rsync'}->{'opts_second'}, "-aH --delete --numeric-ids -e ssh");
	}
}

#root: Different parameters of containers' roots.
#  root_size: Default root size (only for LVMs).
#  root_type: Default root type.
#  fs: Default root filesystem.
sub validate_root
{
	my $class = shift;

	if (!defined($config{'root'})) {
		$config{'root'} = {};
	}

	eval {
		$self->{'valid'}->defaultSize($config{'root'}->{'root_size'}, '50G');
		$self->{'valid'}->defaultEnum($config{'root'}->{'root_type'}, 'lvm', ('lvm', 'file', 'share'));
		$self->{'valid'}->defaultString($config{'root'}->{'fs'}, 'ext4');
	}
}

#root_lvm: Default options for rootfs on LVM.
#  vg: Default volume group.
#  opts: Default logical volume creation options.
sub validate_root_lvm
{
	my $class = shift;

	if (!defined($config{'root_lvm'})) {
		$config{'root_lvm'} = {};
	}

	eval {
		$self->{'valid'}->defaultString($config{'root_lvm'}->{'vg'}, 'vg00');
		$self->{'valid'}->defaultString($config{'root_lvm'}->{'opts'}, '');
	}
}

#root_file: Default options for rootfs in the file.
#  path: Default volume group.
sub validate_root_file
{
	my $class = shift;

	if (!defined($config{'root_file'})) {
		$config{'root_file'} = {};
	}

	eval {
		$self->{'valid'}->defaultDir($config{'root_file'}->{'path'}, '/var/lxc/root/');
	}
}

#templates: Templates' settings.
#  default: Default template.
sub validate_os
{
	my $class = shift;

	if (!defined($config{'templates'})) {
		$config{'templates'} = {};
	}

	eval {
		$self->{'valid'}->defaultString($config{'templates'}->{'default'}, 'ubuntu-10.04-amd64');
	}
}

#network: Different system settings.
#  type: Default network interface type
#  flags: Default network interface flags
#  bridge: Default bridge
#  name: Default network interface name
#  mtu: Default MTU
#  mac_source: Default source for MAC generation
#  searchdomain: Default searchdomain option in /etc/resolv.conf
#  ifname: Default external network interface naming convention
sub validate_network
{
	my $class = shift;

	if (!defined($config{'network'})) {
		$config{'network'} = {};
	}

	eval {
		$self->{'valid'}->defaultString($config{'network'}->{'type'}, 'veth');
		$self->{'valid'}->defaultString($config{'network'}->{'flags'}, 'up');
		$self->{'valid'}->defaultString($config{'network'}->{'bridge'}, 'br0');
		$self->{'valid'}->defaultString($config{'network'}->{'name'}, 'eth');
		$self->{'valid'}->defaultInt($config{'network'}->{'mtu'}, '1450');
		$self->{'valid'}->defaultString($config{'network'}->{'mac_source'}, 'fqdn');
		$self->{'valid'}->defaultString($config{'network'}->{'searchdomain'}, 'example.com');
		$self->{'valid'}->defaultString($config{'network'}->{'ifname'}, 'ip');
	}
}

#list: Different options of container listung.
#  columns: Default columns for `lxctl list` output.
sub validate_list
{
	my $class = shift;

	if (!defined($config{'list'})) {
		$config{'list'} = {};
	}

	eval {
		$self->{'valid'}->defaultString($config{'list'}->{'columns'}, 'name,disk_free_mb,status,ip,hostname');
	}
}

# Get hash and return it validated.
sub validate
{
	my $class;
	($class, %config) = @_;

	validate_paths();
	validate_log();
	validate_check();
	validate_rsync();
	validate_root();
	validate_root_lvm();
	validate_root_file();
	validate_os();
	validate_network();
	validate_list();

	return %config;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'valid'} = new LxctlHelpers::generalValidators;

	return $self;
}

1;
