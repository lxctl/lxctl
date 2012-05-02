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
use Data::Dumper;

my %config;
my %options;
my %append;
my %generalOpts = ();
my $debug = 0;

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

=pod
validate_hash(\%what, \%parameters)
=cut
sub validate_hash
{
	my ($self, $what, $params) = @_;
	print "validate_hash\n" if ($debug >= 1);
	my %parameters = %{$params};

	for my $key (sort keys %parameters) {
		print " DEBUG: validate_hash: $key\n" if ($debug >= 2);
		next if (!defined($params->{"$key"}));
		if (ref($params->{"$key"}) eq "HASH") {
			if (!defined($what->{"$key"})) {
				$what->{"$key"} = {};
			}
			print "  DEBUG: validating: $key with $parameters{$key}\n" if ($debug >= 1);
			$self->validate_hash($what->{"$key"}, $parameters{"$key"});
			next;
		} elsif (ref($params->{"$key"}) ne "ARRAY") {
			print "=====================BEGIN OF DATA DUMP=====================\n";
			print "BUG: Unknown type in 'sub validate_hash' reference on key: $key. Please, send following dump to developers:\n\n";
			print Dumper(%parameters);
			die "======================END OF DATA DUMP======================\n";
		}
		my @val = @{$params->{"$key"}};
		print "  DEBUG: $key, $val[0]\n" if ($debug >= 3);
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
			'ROOT_SIZE' => ['size', '50G'],
			},
		'set' => {
			'SEARCHDOMAIN' => ['str', 'local'],
			},
		'fs' => {
			'FS_OPTS' => ['str', '-b 4096 -E stride=16,stripe-width=32'],
			'FS_MOUNT_OPTS' => ['str', 'defaults,noatime,barrier=0'],
			'FS' => ['str', 'ext4'],
			},
		'lvm' => ['str', 'vg00'],
		);
	$self->validate_hash(\%config, \%configOpts);

	die "No container name specified\n" if (!defined($options{'contname'}));

	%generalOpts = (
			'api_ver' => ['int', 0],
			'autostart' => ['int', 1],
			'debug' => ['int', 0],
			'empty' => ['int', 0],
			'save' => ['int', 1],
			'uuid' => ['uuid', 1],
			'contname' =>  ['str', undef],
			'mkfsopts' =>  ['str', $config{'fs'}->{'FS_OPTS'}],
			'mountoptions' =>  ['str', $config{'fs'}->{'FS_MOUNT_OPTS'}],
			'ostemplate' =>  ['str', $config{'os'}->{'OS_TEMPLATE'}],
			'config' => ['dir', "$config{'os'}->{'CONFIG_DIR'}/$options{'contname'}", 0],
			'searchdomain' =>  ['str', $config{'set'}->{'SEARCHDOMAIN'}],
			'hostname' =>  ['str', $options{'contname'}],
		 	'root' => ['dir', "$config{'root'}->{'MOUNT_PATH'}/$options{'contname'}", 0],
			'rootsz' =>  ['str', $config{'root'}->{'ROOT_SIZE'}],
			'roottype' =>  ['enum', $config{'root'}->{'ROOT_TYPE'}, ['lvm', 'file', 'share']],
			'root_mp' => {
				'roottype' => ['enum', 'lvm', ['lvm', 'file', 'share']],
				'from' => ['str', "/dev/$config{'lvm'}/$options{'contname'}"],
				'fs' => ['str', $config{'fs'}->{'FS'}],
				'opts' => ['str', $config{'fs'}->{'FS_OPTS'}],
				'to' => ['dir', "$config{'root'}->{'MOUNT_PATH'}/$options{'contname'}", 0],
				},
	);
	if (%append) {
		%generalOpts = (%generalOpts, %append);
	}

	$self->validate_hash(\%options, \%generalOpts);

#	validate_uuid;
#	validate_root;
#	validate_root_mp;
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

