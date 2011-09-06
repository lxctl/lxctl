package Lxctl::list;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;
use Lxctl::_getters;
use Lxctl::_config;
use Data::UUID;

sub vsepsimply {
	my ($self, $val) = @_;
	print "\n";
	for (my $i = 0; $i < $val; $i++)
	{
		print "-";
	}
	print "\n";
	return;
}

sub tab {
	my ($self, $val) = @_;
	for (my $i = 0; $i < $val; $i++)
	{
		print " ";
	}
	print "| ";

	return;
}

sub megaprint{
	my ($self, $rows, $columns, @data) = @_;
	my @widths;
	my $widthmatrix = 0;
	$rows++;

	#Determine max length.
	for (my $i = 0; $i < $rows; $i++)
		{
		for (my $j = 0; $j < $columns; $j++)
		{
			if (length($data[$i * $columns + $j]) > ($widths[$j] || 0))
			{
				 $widths[$j] = length($data[$i * $columns + $j]);
			}
		}
	}

	for (my $i = 0; $i < $columns; $i++)
	{
		$widthmatrix += $widths[$i] + 3;
	}

	$self->vsepsimply($widthmatrix + 1);

	for (my $i = 0; $i < $rows; $i++)
	{
		print "| ";
		for (my $j = 0; $j < $columns; $j++)
		{
			print $data[$i * $columns + $j];
			$self->tab($widths[$j] - length ($data[$i * $columns + $j]) + 1);
		}
		$self->vsepsimply($widthmatrix + 1);
	}
}

sub fancy_size {
	my ($self, $val, $to) = @_;
	my $to_lc = lc $to;
	$val = $self->{lxc}->convert_size($val, $to);
	$val =~ s/$to_lc//;
	$val = sprintf ("%.2f", $val);
	return $val;
}

sub get_cpus
{
	my ($self, $name) = @_;
	my $cpu_cnt = 0;
	eval {
		my $cpus = $self->{lxc}->get_cgroup($name, "cpuset.cpus");
		my @splited = split(/,/, $cpus);

		foreach my $part (@splited) {
			if ($part =~ m/(\d+)-(\d+)/) {
				$cpu_cnt += (int($2) - int($1) + 1);
			} else {
				$cpu_cnt += int($part);
			}
		}
		1;
	} or do {
		$cpu_cnt = 2;
	};
	return $cpu_cnt;
}

sub get_all_info
{
	my $self = shift;
	my @vms = $self->{lxc}->ls();
	my @vms_result;
	my $cnt = 0;
	my $lxc_conf_dir = $self->{lxc}->get_lxc_conf_dir();
	my $yaml_conf_dir = $self->{lxc}->get_yaml_config_path();
	my $config_reader = new Lxctl::_config;
	my $vm_option_ref;
	my %vm_option;
	foreach my $vm (@vms) {
		my %info;
		eval {
			$vm_option_ref = $config_reader->load_file("$yaml_conf_dir/$vm.yaml");
			%vm_option = %$vm_option_ref;
			if (!defined($vm_option{'uuid'})) {
				my $ug = new Data::UUID;
				$vm_option{'uuid'} = $ug->create_str();
				$config_reader->save_hash(\%vm_option, "$yaml_conf_dir/$vm.yaml");
			}
			$info{'uuid'} = $vm_option{'uuid'};
			$info{'mac'} = uc($self->{helper}->get_config($lxc_conf_dir."/$vm/config", "lxc.network.hwaddr"));
			$info{'disksize'} = int($self->{lxc}->convert_size($vm_option{'rootsz'}, "MiB", 0));
			$info{'template'} = $vm_option{'ostemplate'};
			$vm_option{'mem'} ||= 0;
			$info{'mem'} = int($self->{lxc}->convert_size($vm_option{'mem'}, "MiB", 0));
			$info{'name'} = $vm_option{'contname'};
			$info{'cpus'} = $self->get_cpus($vm_option{'contname'});
			$info{'status'} = lc($self->{lxc}->status($vm));;
			push(@vms_result, \%info);
			$cnt++;
			1;
		} or do {
			print "[ERR]: $@\n";
		};
	}
	return @vms_result;
}

sub do
{
	my $self = shift;

	use constant {
		TAB_WIDTH => 15,
		dVM_NAME => 7,
		dSTATE => 5,
		dHOSTNAME => 8,
		dIPADDR => 2,
		dDS_FREE => 10,
		dDS_ALL => 11,
		dCG_MEM => 12,
		dCG_CPUS => 11,
		dCG_SHARES => 10,
		dMOUNTPOINT => 11,
		MIN_COL => 2,
		MAX_MEM => 2097152,
		SPACE_VAL => "Gb",
	};
	my @data;
	my $count = 0;
	my $ipaddr = 0;
	my $hostname = 0;
	my $cgroup = 0;
	my $all = 0;
	my $disk_space = 0;
	my $mount_point = 0;
	my $countvm = 0;
	my $raw = 0;
	my $cols = MIN_COL;
	my $getters = new Lxctl::_getters;
	GetOptions('ipaddr' => \$ipaddr, 'hostname' => \$hostname, 'cgroup' => \$cgroup, 'diskspace' => \$disk_space, 'mount' => \$mount_point,
'raw' => \$raw, 'all' => \$all);

	if ($raw) {
		my @vms = $self->{lxc}->ls();
		foreach my $vm (@vms) {
			print "$vm ";
		}
		print "\n";
		return;
	}

	if ($all) { $ipaddr = 1; $hostname = 1; $disk_space = 1; $cgroup = 1; $mount_point = 1; }

	my @vms = $self->{lxc}->ls();
	$cols += $ipaddr + $hostname + $disk_space + $mount_point + $cgroup*3;
	#Printing header
	$data[$count++] = "VM_NAME";
	$data[$count++] = "STATE";
	
	if ($hostname) {
		$data[$count++] = "hostname" 
	}

	if ($ipaddr) {
		$data[$count++] = "ip";
	}

	if ($mount_point) {
		$data[$count++] = "mount point";
	}

	if ($disk_space){
		$data[$count++] = "free/size";
	}
	
	if ($cgroup) {
		$data[$count++] = "memory limit";
		$data[$count++] = "cpuset.cpus";
		$data[$count++] = "cpu.shares";
	}

	foreach my $vm (@vms){
		my $vm_state = $self->{lxc}->status($vm);
		my $root_path = "N/A";
		my $ghoststate = 0;
		eval {
			$root_path = $self->{lxc}->get_conf($vm, "lxc.rootfs");
		} or do {$vm_state = "GHOST"; $ghoststate = 1;};	
		$countvm++;
		$data[$count++] = "$vm";
		$data[$count++] = "$vm_state";

		if ($hostname) {
				if (!$ghoststate) {
					$data[$count++] = $self->{lxc}->get_conf($vm, "lxc.utsname");
				} else {
					$data[$count++] = "N/A";
				}
		}


		if ($ipaddr) {
			if (!$ghoststate) {
				$data[$count++] = $getters->get_ip($vm);
			} else {
				$data[$count++] = "N/A";
			}
		}

		if ($mount_point) {
			$data[$count++] = $root_path;
		}

		if ($disk_space && $vm_state ne "STOPPED" && $vm_state ne "GHOST") {
			my $text = `df -B 1 $root_path`;
			my (@digits) = $text =~ m/(\s\d\d\d\d+)/g;
			my $tmp =  $self->fancy_size($digits[2], SPACE_VAL);
			$data[$count] = $tmp . "/";

			$tmp = $self->fancy_size($digits[0], SPACE_VAL);
			$data[$count] .= $tmp . " " . SPACE_VAL;
			$count++;
		} elsif ($disk_space) {
			$data[$count++] = "N/A";
		}

		if ($cgroup) {
			my $tmp;
			eval {
				$data[$count] = $self->{lxc}->get_cgroup($vm, "memory.limit_in_bytes");
				$data[$count] = $self->{lxc}->convert_size($data[$count], "MB");
				$data[$count] =~ s/\n//;

				1;
			} or do {
				# By default memory isn't limited.
				# Setting to MAX
				$data[$count] = MAX_MEM + 1;
			};

			($tmp) = $data[$count] =~ m/(\d+)/ms;
			if ($tmp > MAX_MEM) {
				# It's unlikly that somebody would have >2TB of RAM.
				$data[$count] = "Unlim";
			}

			$count++;

			eval {
				$data[$count] = $self->{lxc}->get_cgroup($vm, "cpuset.cpus");
				$data[$count++] =~ s/\n//;

				1;
			} or do {
				# By default pid will got all CPUs
				$data[$count++] = "All";
			};

			eval {
				$data[$count] = $self->{lxc}->get_cgroup($vm, "cpu.shares");
				$data[$count++] =~ s/\n//;

				1;
			} or do {
				# Default cpu.shares is 1024
				$data[$count++] = "1024";
			};
		}
	}
	$self->megaprint($countvm, $cols, @data);
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{lxc} = new Lxc::object;
	$self->{helper} = new Lxctl::helper;
	return $self;
}

1;
__END__
=head1 NAME

Lxctl::destroy

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

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
