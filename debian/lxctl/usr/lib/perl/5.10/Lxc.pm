#!/usr/bin/perl

package Lxc;

use warnings;
use strict;
use 5.010001;
use Carp;
use POSIX;

our $CONFIG_PATH = "/etc/lxc";
our $ROOTS_PATH = "/var/lxc/root";
our $TEMPLATES_PATH = "/var/lxc/templates";
our $LXC_CONF_DIR = "/var/lib/lxc";
our $CGROUP_PATH = "/cgroup";
our $VG = "vg00";

our %signals;

%signals = (
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
sub set_path {
	my ($confdir) = @_;
	my $subname = (caller(0))[3];
	if (!defined($confdir)) {
		croak "$subname: No parameter is given\n"; 
	}

	$LXC_CONF_DIR = $confdir;
	return 1;
}

# Internal function
# Check if 2-nd param is set to y or m in file by 1-st param
sub is_inconfig {
	my ($config_name, $find) = @_;
	my $subname = (caller(0))[3];
	open my $config_file, '<' , $config_name or croak "$subname: Cannot open config \"$config_name\": $!";
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
	my ($signal) = @_;
	if ( $signal =~ /^SIG/  ) {
		return $signals{"$signal"};
	} else {
		my $sig = "SIG" . $signal;
		return $signals{"$sig"};
	}
}

# Check if kernel supports LXC, or die.
sub check {
	use integer;
	use Term::ANSIColor;
	# 2-dim array with kernel's config options.
	# 1-st - option name
	# 2-nd - is it required or optional
	# if optional CONFIG is missing it'll result in warning
	my @config_opts = (
		["CONFIG_NAMESPACES", 1],
		["CONFIG_UTS_NS", 1],
		["CONFIG_IPC_NS", 1],
		["CONFIG_PID_NS", 1],
		["CONFIG_USER_NS", 0],
		["CONFIG_NET_NS", 0],
		["DEVPTS_MULTIPLE_INSTANCES", 0],
		["CONFIG_CGROUPS", 1],
		["CONFIG_CGROUP_NS", 0],
		["CONFIG_CGROUP_DEVICE", 0],
		["CONFIG_CGROUP_SCHED", 0],
		["CONFIG_CGROUP_CPUACCT", 0],
		["CONFIG_CGROUP_MEM_RES_CTLR", 0],
		["CONFIG_CPUSETS", 0],
		["CONFIG_VETH", 0],
		["CONFIG_MACVLAN", 0],
		["CONFIG_VLAN_8021Q", 0]
	);
	my $kver = `uname -r`;
	my $errors = 0;
	my $warns = 0;
	chop($kver);
	my $headers_config = "/lib/modules/$kver/build/.config";
	my $config = "/boot/config-$kver";

	if ($> != 0) {
		print color 'bold red';
		print "Error: you are not root!\n";
		print color 'reset';
		$errors++;
	}

	
	foreach my $opt (@config_opts) {
		if (is_inconfig($config, @$opt[0]) != 0) {
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
	if ($warns != 0 || $errors != 0) {
		print "Errors: $errors\nWarnings: $warns\n";
	}
	if ($errors != 0) {
		croak "Too many errors in config file. LXC won't work properly\n";
	}
}

# Get state for VMName givven in first parameter.
# if no parameter is given returns empty string.
sub status {
	my ($name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		print "$subname: No vmname is given\n";
		return "";
	}
	my $status = `lxc-info --name $name`;
	my ($match) = $status =~ m/([A-Z]+$)/;
	return $match;
}

# Returns all existing VMs in array
sub ls {
	my @list;
	my $subname = (caller(0))[3];

	opendir (DIR, $LXC_CONF_DIR) or croak "$subname: $LXC_CONF_DIR: $!";
	@list = grep {! /^\./ && -d "$LXC_CONF_DIR/$_" } readdir(DIR);
	closedir(DIR);

	return @list;
}

# Attachs to running container. Equivalent to vzctl enter
# Returns 0 on success and NO_NAME or output on failure.
sub attach {
	my ($name) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}
	my $status = system("lxc-attach --name $name 2>&1");
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Suspends running container.
# Returns 0 on success, NO_NAME or output on failure
sub freeze {
	my ($name) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}
	my $status = `lxc-freeze --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Resume suspended container.
# Returns 0 on success, 1 on failure
sub unfreeze {
	my ($name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}
	my $status = `lxc-unfreeze --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Kills 1-st process of container $NAME with signal $SIG
# Requires 2 parameters.
# Returns NO_NAME, NO_SIG or output if error and 0 on success.
# Signal can be either number or name
sub Kill {
	my ($name, $signal) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	if (!defined($signal)) {
		croak "$subname: No signal name is given\n";
	}

	if ($signal =~ /\D/) {
		$signal = signal_to_int($signal);
	}

	my $status = `lxc-kill --name $name $signal 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Start container of NAME=$1
# Config file is $2 (optional)
# Write all output to $3 (optional)
# Return 0 on success, NO_NAME or output on failure
sub start {
	my ($name, $file, $log) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	my $myarg="--name $_[0]";

	if (defined($file)) {
		if ($file ne "") {
			$myarg = $myarg . " -f $file";
		}
	}

	if (defined($log)) {
		if ($log ne "") {
			$myarg = $myarg . " -c $log";
		}
	}

	my $status = `lxc-start $myarg -d 2>&1`;
	chop($status);
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Stop container with name $1
# Returns 0 on success
sub stop {
	my ($name) = @_;
	my $subname = (caller(0))[3];
	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}
	my $status = `lxc-stop --name $name 2>&1`;
	if ($status eq "") {
		return 1;
	} else {
		croak "$subname: $status\n";
	}
}

# Get parameter from VM's config
# 1-st param is vmname
# 2-nd param is what config field to get
sub get_conf {
	my ($name, $param) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	if (!defined($param)) {
		croak "$subname: No config param\n";
	}

	open my $config_file, '<', "$LXC_CONF_DIR/$name/config" or
		croak "$subname: Cannot open config $LXC_CONF_DIR/$name/config";

	my @config = <$config_file>;
        my @conf = grep { /$param/ } @config;
	if (defined($conf[0])) {
	        $conf[0] =~ s/$param[ ]=[ ]//g;
		$conf[0] =~ s/\/\//\//;
		chop($conf[0]);
		close $config_file;
		
		return $conf[0];
	} else {
		close $config_file;
		croak "$subname: Config option not found";
	}
}

sub set_conf {
	my ($name, $conf, $value) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	if (!defined($conf)) {
		croak "$subname: No option name\n";
	}

	if (!defined($value)) {
		croak "$subname: No config value\n";
	}

	open(my $conf_file, '<', "$LXC_CONF_DIR/$name/config") or
		croak " Failed to open $LXC_CONF_DIR/$name/config for reading\n";

	my @conf = <$conf_file>;

	close $conf_file;

	my $search_exists = 0;

	open($conf_file, '>', "$LXC_CONF_DIR/$name/config") or
		croak " Failed to open $LXC_CONF_DIR/$name/config for writing\n";

	for my $line (@conf) {
		$search_exists = 1 if $line =~ s/($conf\s*=\s*).*$/$1 $value/g;
		print $conf_file $line;
	}

	print $conf_file "\n$conf = $value\n" if $search_exists == 0;

	close $conf_file;

	return 1;
}

sub get_ip{
	my ($name) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	my $path=get_conf($name, "lxc.rootfs");
	$path = $path . "/etc/network/interfaces";

	open my $config_file, '<', "$path" or return "N/A";

	my @interfaces = <$config_file>;
	my @ip = grep { /address / } @interfaces;
	$ip[0] =~ s/  address //;
	chop($ip[0]);

	close($config_file);

	return "$ip[0]";
}

sub get_cgroup{
	my ($name, $group) = @_;
	my $subname = (caller(0))[3];
	my $result;

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	if (!defined($group)) {
		croak "$subname: No cgroup is given\n";
	}

	if ( -f "/cgroup/$name/$group" ) {
		open my $cgroup_file, "<", "/cgroup/$name/$group" or return 1;
		$result = <$cgroup_file>;
		close ($cgroup_file);
	} else {
		# TODO: Check if cgroup is mounted and warn if not.
		$result = get_conf($name, "lxc.cgroup." . $group);
	}

	return $result;
}

sub set_cgroup{
	my ($name, $group, $value) = @_;
	my $subname = (caller(0))[3];

	if (!defined($name)) {
		croak "$subname: No vmname is given\n";
	}

	if (!defined($group)) {
		croak "$subname: No cgroup is given\n";
	}

	if (!defined($value)) {
		croak "$subname: No value is given\n";
	}

	if ( -f "/cgroup/$name/$group" ) {
		open my $cgroup_file, ">", "/cgroup/$name/$group"
			or croak "Failed to open /cgroup/$name/$group";
		print $cgroup_file $value;
		close ($cgroup_file);
	} else {
		# TODO: Check if cgroup is mounted and warn if not.
		croak "$subname: Cgroup file doesn't exists\n";
	}

	return 1;
}

sub convert_size{
	my ($from, $to) = @_;
	my $subname = (caller(0))[3];

	my %convert = (
		'b' => 0,
		'k' => 1, 'kib' => 1, 'kb' => 1,
		'm' => 2, 'mib' => 2, 'mb' => 2,
		'g' => 3, 'gib' => 3, 'gb' => 3,
		't' => 4, 'tib' => 4, 'tb' => 4,
		'p' => 5, 'pib' => 5, 'pb' => 5,
		'e' => 6, 'eib' => 6, 'eb' => 6
	);

	if (!defined($from)) {
		croak "$subname: Nothing to convert\n";
	}

	if (!defined($to)) {
		croak "$subname: My master, I'm kindly sorry, but I don't know what units do you want me to convert this value to.\n";
	}

	$to = lc $to;
	$from = lc $from;

	if (! exists($convert{$to})) {
		croak "$subname: My master, I'm kindly sorry, but I don't know what units do you want me to convert this value to.\n";
	}


	my ($value, $postfix) = $from =~ m/(\d+)([a-z]*)/mxs;
	if (!defined($postfix)) {
		$postfix = "b";
	}

	if (!defined($value)) {
		croak "$subname: Non-numeric value! Aborting...\n";
	}

	my $tmp = POSIX::pow(1024,$convert{$postfix})*$value;
	$tmp = $tmp/POSIX::pow(1024,$convert{$to});

	if ($to ne 'b') {
		$tmp = $tmp . uc $to;
	}

	return $tmp;
}

1;
