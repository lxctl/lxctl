#!/usr/bin/perl

package Lxc::object;

use warnings;
use strict;
use 5.010001;
use POSIX;
use Exporter qw(import);
use feature 'state';

my %signals = (
	'SIGHUP' => 1,
	'SIGINT' => 2,
	'SIGQUIT' => 3,
	'SIGILL' => 4,
	'SIGTRAP' => 5,
	'SIGABRT' => 6,
	'SIGIOT' => 6,
	'SIGBUS' => 7,
	'SIGFPE' => 8,
	'SIGKILL' => 9,
	'SIGUSR1' => 10,
	'SIGSEGV' => 11,
	'SIGUSR2' => 12,
	'SIGPIPE' => 13,
	'SIGALRM' => 14,
	'SIGTERM' => 15,
	'SIGSTKFLT' => 16,
	'SIGCHLD' => 17,
	'SIGCONT' => 18,
	'SIGSTOP' => 19,
	'SIGTSTP' => 20,
	'SIGTTIN' => 21,
	'SIGTTOU' => 22,
	'SIGURG' => 23,
	'SIGXCPU' => 24,
	'SIGXFSZ' => 25,
	'SIGVTALRM' => 26,
	'SIGPROF' => 27,
	'SIGWINCH' => 28,
	'SIGIO' => 29,
	'SIGPOLL' => 29,
	'SIGPWR' => 30,
	'SIGSYS' => 31,
	'SIGUNUSED' => 31,
);

# sets path to container storage
# returns 0 if success


#For compatibility. Remove later
sub set_config_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{YAML_CONFIG_PATH} = $confdir;
	return 1;
}

sub get_config_path {
	my ($self) = @_;

	return $self->{YAML_CONFIG_PATH};
}

sub set_roots_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{ROOT_MOUNT_PATH} = $confdir;
	return 1;
}

sub get_roots_path {
	my ($self) = @_;

	return $self->{ROOT_MOUNT_PATH};
}

# New setters getters for local configs.
sub set_yaml_config_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{YAML_CONFIG_PATH} = $confdir;
	return 1;
}

sub get_yaml_config_path {
	my ($self) = @_;

	return $self->{YAML_CONFIG_PATH};
}

sub set_root_mount_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{ROOT_MOUNT_PATH} = $confdir;
	return 1;
}

sub get_root_mount_path {
	my ($self) = @_;

	return $self->{ROOT_MOUNT_PATH};
}

sub set_template_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{TEMPLATE_PATH} = $confdir;
	return 1;
}

sub get_template_path {
	my ($self) = @_;

	return $self->{TEMPLATE_PATH};
}

sub set_lxc_conf_dir {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{LXC_CONF_DIR} = $confdir;
	return 1;
}

sub get_lxc_conf_dir {
	my ($self) = @_;

	return $self->{LXC_CONF_DIR};
}

sub set_cgroup_path {
	my ($self, $confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{CGROUP_PATH} = $confdir;
	return 1;
}

sub get_cgroup_path {
	my ($self) = @_;

	return $self->{CGROUP_PATH};
}

sub set_vg {
	my ($self, $conf) = @_;
	my $subname = (caller(0))[3];
	if (!defined($conf)) {
		die "$subname: No parameter is given\n"; 
	}

	$self->{VG} = $conf;
	return 1;
}

sub get_vg {
	my ($self) = @_;
	return $self->{VG};
}

sub get_conf_check {
	my ($self) = @_;
	return $self->{'skip_conf_check'};
}

sub set_conf_check {
	my ($self, $check) = @_;
	$self->{'skip_conf_check'} = $check;
}

# Internal function
# Check if 2-nd param is set to y or m in file by 1-st param
sub is_inconfig {
	my ($self, $config_name, $find) = @_;
	my $subname = (caller(0))[3];
	open my $config_file, '<' , $config_name or die "$subname: Cannot open config \"$config_name\": $!";
	while (<$config_file>) {
		if ($_ =~/$find=[ym]+/ ) {
			close $config_file;
			return 0;
		}
	}
	close $config_file;
	
	return 1;
}

sub signal_to_int {
	my ($self, $signal) = @_;
	if ( $signal =~ /^SIG/  ) {
		return $signals{"$signal"};
	} else {
		my $sig = "SIG" . $signal;
		return $signals{"$sig"};
	}
}

# Check if kernel supports LXC, or die.
sub check {
	my ($self) = @_;
	use integer;
	use Term::ANSIColor;
	my $errors = 0;
	my $warns = 0;

	if ($> != 0) {
		print color 'bold red';
		print "Error: you are not root!\n";
		print color 'reset';
		$errors++;
	}

	if (!$self->{'skip_conf_check'}) {
		# 5-dim array with kernel's config options.
		# 1-st - option name
		# 2-nd - is it required or optional
		# 3-5 is kernel version, when this option was removed from config.
		# if optional CONFIG is missing it'll result in warning
		my @config_opts = (
			["CONFIG_NAMESPACES", 1, 99, 99, 99],
			["CONFIG_UTS_NS", 1, 99, 99, 99],
			["CONFIG_IPC_NS", 1, 99, 99, 99],
			["CONFIG_PID_NS", 1, 99, 99, 99],
			["CONFIG_USER_NS", 0, 99, 99, 99],
			["CONFIG_NET_NS", 0, 99, 99, 99],
			["DEVPTS_MULTIPLE_INSTANCES", 1, 99, 99, 99],
			["CONFIG_CGROUPS", 1, 99, 99, 99],
			["CONFIG_CGROUP_NS", 0, 3, 0, 0],
			["CONFIG_CGROUP_DEVICE", 0, 99, 99, 99],
			["CONFIG_CGROUP_SCHED", 0, 99, 99, 99],
			["CONFIG_CGROUP_CPUACCT", 0, 99, 99, 99],
			["CONFIG_CGROUP_MEM_RES_CTLR", 0, 99, 99, 99],
			["CONFIG_CPUSETS", 0, 99, 99, 99],
			["CONFIG_VETH", 0, 99, 99, 99],
			["CONFIG_MACVLAN", 0, 99, 99, 99],
			["CONFIG_VLAN_8021Q", 0, 99, 99, 99]
		);
		my $kver = `uname -r`;
		chop($kver);
		my ($kver_1, $kver_2, $kver_3) = $kver =~ m/(\d+)\.(\d+)\.*(\d*)/;
		my $kver_big = $kver_3 + $kver_2 * 1000 + $kver_1*1000*1000;

		my $headers_config = "/lib/modules/$kver/build/.config";
		my $config = "/boot/config-$kver";


		foreach my $opt (@config_opts) {
			my $test_ver_big = @$opt[4] + @$opt[3]*1000 + @$opt[2]*1000*1000;
			if ($test_ver_big > $kver_big) {
				if ($self->is_inconfig($config, @$opt[0]) != 0) {
					if (@$opt[1] == 0) {
						print color 'bold yellow';
						print "Warning: @$opt[0] not supported\n";
						print color 'reset';
						$warns++;
					} else {
						print color 'bold red';
						print "Error: @$opt[0] not supported\n";
						print color 'reset';
						$errors++;
					}
				}
			}
}
	}

	if ($warns != 0 || $errors != 0) {
		print "Errors: $errors\nWarnings: $warns\n";
	}
	if ($errors != 0) {
		die "Too many errors in config file. LXC won't work properly\n";
	}
}

# Get state for VMName givven in first parameter.
# if no parameter is given returns empty string.
sub status {
	my ($self, $name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		print "$subname: No vmname is given\n";
		return "";
	}
	my $status = `lxc-info --name $name 2>&1`;
	my $lxc_upstream_version = `lxc-version`;
	$lxc_upstream_version =~ s#.*\s+(\d.*)#$1#;
	my @lxc_version_tokens = split(/\./, $lxc_upstream_version);
	my $match;
	if ($lxc_version_tokens[0] eq 0 && ($lxc_version_tokens[1] > 7 || ($lxc_version_tokens[1] eq 7 && $lxc_version_tokens[2] > 4))) {
		($match) = $status =~ m/state:\s+([A-Z]+)/;
	} else {
		($match) = $status =~ m/([A-Z]+$)/;
	}
	return $match;
}

# Returns all existing VMs in array
sub ls {
	my ($self) = @_;
	my @list;
	my %vms;
	my $confpath;
	my $tmp;
	my $key;
	my $subname = (caller(0))[3];

	opendir (my $vm_dir, $self->{LXC_CONF_DIR}) or die "$subname: $self->{LXC_CONF_DIR}: $!";
	@list = grep {! /^\./ && -d "$self->{LXC_CONF_DIR}/$_" } readdir($vm_dir);
	closedir($vm_dir);

	# For each found Container we'll define element in hash.
	# Then add all running vm's if they are already added
	# And only after that sort keys of hash and return them
	foreach $key (@list) {
		$vms{$key} = '';
	}

#	Listing all running vm and defining key in hash for them
	@list = `netstat -xa`;
	@list = grep /$self->{LXC_CONF_DIR}/, @list;
	foreach $key (@list)
	{
		($tmp) = $key =~ m%$self->{LXC_CONF_DIR}/(.*)/command%;
		$vms{$tmp} = '';
	}

	@list = sort keys %vms;
	return @list;
}

# Attachs to running container. Equivalent to vzctl enter
# Returns 0 on success and NO_NAME or output on failure.
sub attach {
	my ($self, $name) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}
	my $status = system("lxc-attach --name $name 2>&1");
	if ($status eq "0") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Suspends running container.
# Returns 0 on success, NO_NAME or output on failure
sub freeze {
	my ($self, $name) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}
	my $status = `lxc-freeze --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Resume suspended container.
# Returns 0 on success, 1 on failure
sub unfreeze {
	my ($self, $name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}
	my $status = `lxc-unfreeze --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Kills 1-st process of container $NAME with signal $SIG
# Requires 2 parameters.
# Returns NO_NAME, NO_SIG or output if error and 0 on success.
# Signal can be either number or name
sub Kill {
	my ($self, $name, $signal) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}

	if (!defined($signal)) {
		die "$subname: No signal name is given\n";
	}

	if ($signal =~ /\D/) {
		$signal = $self->signal_to_int($signal);
	}

	my $status = `lxc-kill --name $name $signal 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Start container of NAME=$1
# Config file is $2 (optional)
# Write all output to $3 (optional)
# Return 0 on success, dies on failure
sub start #(name, daemon, config_file, log_file)
{
	my ($self, $name, $daemon, $file, $log) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}

	my $myarg="--name $name";

	if (defined($file)) {
		if ($file ne "") {
			$myarg = $myarg . " -f $file";
		}
	}

	if (defined($daemon)) {
		if ($daemon == 1) {
			$myarg = $myarg . " -d";
		}
	} else {
		$myarg = $myarg . " -d";
	}

	if (defined($log)) {
		if ($log ne "") {
			$myarg = $myarg . " -c $log";
		}
	}

	my $status = `lxc-start $myarg 2>&1`;
	chop($status);
	if ($status eq "") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Stop container with name $1
# Returns 0 on success
sub stop {
	my ($self, $name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}
	my $status = `lxc-stop --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		die "$subname: $status\n";
	}
}

# Get parameter from VM's config
# 1-st param is vmname
# 2-nd param is what config field to get
sub get_conf {
	my ($self, $name, $param) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		die "$subname: No vmname is given\n\n";
	}

	if (!defined($param)) {
		die "$subname: No config param defined\n\n";
	}

	open my $config_file, '<', "$self->{LXC_CONF_DIR}/$name/config" or
		die "$subname: Cannot open config $self->{LXC_CONF_DIR}/$name/config";

	my @config = <$config_file>;
	my @conf = grep { /$param/ } @config;
	if (defined($conf[0])) {
	        $conf[0] =~ s/$param[ ]+=[ ]+//g;
		$conf[0] =~ s/\/\//\//;
		chop($conf[0]);
		close $config_file;
		
		return $conf[0];
	} else {
		close $config_file;
		die "$subname: Config option not found";
	}
}

sub set_conf {
	my ($self, $name, $conf, $value) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}

	if (!defined($conf)) {
		die "$subname: No option name\n";
	}

	if (!defined($value)) {
		die "$subname: No config value\n";
	}

	open(my $conf_file, '<', "$self->{LXC_CONF_DIR}/$name/config") or
		die " Failed to open $self->{LXC_CONF_DIR}/$name/config for reading\n";

	my @conf = <$conf_file>;

	close $conf_file;

	my $search_exists = 0;

	open($conf_file, '>', "$self->{LXC_CONF_DIR}/$name/config") or
		die " Failed to open $self->{LXC_CONF_DIR}/$name/config for writing\n";

	for my $line (@conf) {
		$search_exists = 1 if $line =~ s/($conf\s*=\s*).*$/$1 $value/g;
		print $conf_file $line;
	}

	print $conf_file "\n$conf = $value\n" if $search_exists == 0;

	close $conf_file;	my ($from, $to) = @_;

	return 1;
}

sub get_cgroup{
	my ($self, $name, $group) = @_;
	my $subname = (caller(0))[3];
	my $result;

	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}

	if (!defined($group)) {
		die "$subname: No cgroup is given\n";
	}

	if ( -f "$self->{CGROUP_PATH}/$name/$group" ) {
		open my $cgroup_file, "<", "$self->{CGROUP_PATH}/$name/$group" or die "Can't open file";
		$result = <$cgroup_file>;
		close ($cgroup_file);
	} else {
		# TODO: Check if cgroup is mounted and warn if not.
		$result = $self->get_conf($name, "lxc.cgroup." . $group);
		($result) = $result =~ m/((\d|,|-)+$)/;
	}

	return $result;
}

sub set_cgroup{
	my ($self, $name, $group, $value, $force) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		die "$subname: No vmname is given\n";
	}

	if (!defined($group)) {
		die "$subname: No cgroup is given\n";
	}

	if (!defined($value)) {
		die "$subname: No value is given\n";
	}

	if (!defined($force)) {
		$force = 0;
	}

	if ( -f "$self->{CGROUP_PATH}/$name/$group" ) {
		open my $cgroup_file, ">", "/cgroup/$name/$group"
			or die "Failed to open /cgroup/$name/$group";
		print $cgroup_file "$value";
		close ($cgroup_file);
		if ($force) {
			my $group_tmp = "lxc.cgroup." . $group;
			$self->set_conf($name, $group_tmp, $value);
		}
	} else {
		# TODO: Check if cgroup is mounted and warn if not.
		if ($force) {
			my $group_tmp = "lxc.cgroup." . $group;
			$self->set_conf($name, $group_tmp, $value);
		} else {
			die "$subname: $self->{CGROUP_PATH}/$name/$group doesn't exists, aborted...\n\n";
		}
	}

	return 1;
}

sub convert_size{
	my ($self, $from, $to) = @_;
	my $subname = (caller(0))[3];

	my %convert = (
		'b' => 0, '' => 0,
		'k' => 1, 'kib' => 1, 'kb' => 1,
		'm' => 2, 'mib' => 2, 'mb' => 2,
		'g' => 3, 'gib' => 3, 'gb' => 3,
		't' => 4, 'tib' => 4, 'tb' => 4,
		'p' => 5, 'pib' => 5, 'pb' => 5,
		'e' => 6, 'eib' => 6, 'eb' => 6,
	);

	if (!defined($from)) {
		die "$subname: Nothing to convert\n";
	}

	if (!defined($to)) {
		die "$subname: My master, I'm kindly sorry, but I don't know what units do you want me to convert this value to.\n";
	}

	$to = lc $to;
	$from = lc $from;

	if (! exists($convert{$to})) {
		die "$subname: My master, I'm kindly sorry, but I don't know what units do you want me to convert this value to.\n";
	}


	my ($value, $postfix) = $from =~ m/(\d+)([a-z]*)/ms;
	if (!defined($postfix)) {
		$postfix = "b";
	}

	if (!defined($value)) {
		die "$subname: Non-numeric value! Aborting...\n";
	}

	my $tmp = POSIX::pow(1024, $convert{$postfix}-$convert{$to}) * $value;

	if ($to ne 'b') {
		$tmp = $tmp . $to;
	}

	return $tmp;
}

sub new {
	my ($class, $skip_conf_check) = @_;
	state $instance;

	if (! defined $instance) {
		$instance = bless {}, $class;
		$instance->init();
		if (defined($skip_conf_check)) {
			$instance->{'skip_conf_check'} = $skip_conf_check;
		} else {
			$instance->{'skip_conf_check'} = 0;
		}
	}

	return $instance;
}

sub init {
	my ($self) = @_;
	$self->{CONFIG_PATH} = "/etc/lxctl";
	$self->{ROOTS_PATH} = "/var/lxc/root";
	$self->{TEMPLATE_PATH} = "/var/lxc/templates";
	$self->{LXC_CONF_DIR} = "/var/lib/lxc";
	$self->{CGROUP_PATH} = "/cgroup";
	$self->{VG} = "vg00";
}

1;

__END__
=head1 NAME

Lxc::object

=head1 SYNOPSIS

Simple OO-wrapper around lxctl. Tested with lxctl 0.7.4.2

=head1 DESCRIPTION

Simple OO-wrapper around lxctl. Tested with lxctl 0.7.4.2.

=head2 EXPORT

None by default.

=head2 Exportable constants

None by default.

=head2 Exportable functions

set_config_path($confdir)
get_config_path()
set_roots_path($confdir)
get_roots_path()
set_template_path($confdir)
get_template_path()
set_lxc_conf_dir($confdir)
get_lxc_conf_dir()
set_cgroup_path($confdir)
get_cgroup_path()
set_vg($confdir)
get_vg()
set_conf_check($val)
get_conf_check()
check()
ls()
attach($container_name)
freeze($container_name)
unfreeze($container_name)
start($container_name)
stop($container_name)
Kill($container_name, $signal)
get_conf($container_name, $parameter_name)
set_conf($container_name, $parameter_name, $value)
_deprecated_ get_ip($container_name) # Will be removed in future version
get_cgroup($container_name, $parameter)
set_cgroup($container_name, $parameter_name, $value, $force): If force is specified, set cgroup param in config even if machine is stoped
convert_size($from, $to): Converts from bytes/kib/mib/gib/pib/eib to what was specified. Ex: convert_size("20KB", "MB");

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
