package Lxctl::list;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;
use LxctlHelpers::getters;
use LxctlHelpers::config;
use Data::UUID;
use List::Util qw[max];

my $getters = new LxctlHelpers::getters;
my %sizes;
my $sep = "  ";
my $config_reader = new LxctlHelpers::config;

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

	my $vm_option_ref;
	my %vm_option;
	foreach my $vm (@vms) {
		my %info;
		my $root_path;
		my $ghost = 0;
		$vm_option_ref = $config_reader->load_file("$yaml_conf_dir/$vm.yaml");
		%vm_option = %$vm_option_ref;

		eval {
			$root_path = $self->{lxc}->get_conf($vm, "lxc.rootfs");
		} or do {
			$root_path = "N/A";
			$ghost = 1;
		};
		if (!defined($vm_option{'uuid'})) {
			my $ug = new Data::UUID;
			$vm_option{'uuid'} = $ug->create_str();
			$config_reader->save_hash(\%vm_option, "$yaml_conf_dir/$vm.yaml");
		}
		$info{'uuid'} = $vm_option{'uuid'};
		$info{'mac'} = uc($self->{helper}->get_config($lxc_conf_dir."/$vm/config", "lxc.network.hwaddr"));
		$info{'disksize_mb'} = int($self->{lxc}->convert_size($vm_option{'rootsz'}, "MiB", 0));
		$info{'template'} = $vm_option{'ostemplate'};
		$vm_option{'mem'} ||= "1EB";
		$info{'memory_mb'} = int($self->{lxc}->convert_size($vm_option{'mem'}, "MiB", 0));
		$info{'name'} = $vm_option{'contname'};
		$info{'cpus'} = $self->get_cpus($vm_option{'contname'});
		eval {
			$info{'cpu'} = $self->{lxc}->get_cgroup($vm, "cpuset.cpus");
			1;
		} or do {
			# By default pid will got all CPUs
			$info{'cpu'} = "All";
		};
		eval {
			$info{'cpushares'} = $self->{lxc}->get_cgroup($vm, "cpu.shares");
			1;
		} or do {
			$info{'cpushares'} = 1024;
		};
		eval {
			my $ip = $getters->get_ip($vm);
			($info{'ip'}) = $ip =~ m/(\d+\.\d+\.\d+\.\d+)/;
			1;
		} or do {
			$info{'ip'} = "N/A";
		};
		eval {
			$info{'hostname'} = $self->{lxc}->get_conf($vm, "lxc.utsname");
			1;
		} or do {
			$info{'hostname'} = "N/A";
		};
		if ($ghost == 0) {
			my $df = `df -B 1 $root_path`;
			my ($total, $free) = $df =~ m/\s+(\d+)\s+(\d+)/g;

			if (defined($total)) {
				$info{'disk_total_mb'} =  sprintf("%.2f", $self->{lxc}->convert_size($total, 'MiB', 0));
				$info{'disk_free_mb'} =  sprintf("%.2f", $self->{lxc}->convert_size($free, 'MiB', 0));
			} else {
				$info{'disk_total_mb'} = "N/A";
				$info{'disk_free_mb'} = "N/A";
			}
			$info{'status'} = lc($self->{lxc}->status($vm));
		} else {
			$info{'disk_total_mb'} = "N/A";
			$info{'disk_free_mb'} = "N/A";
			$info{'status'} = "ghost";
		};
		
		foreach my $key (sort keys %info) {
			if (!defined($sizes{$key}) || ($sizes{$key} < length($info{$key}))) {
				$sizes{$key} = max(length($info{$key}), length($key));
			}
		}
		
		push(@vms_result, \%info);
		$cnt++;
	}
	return @vms_result;
}

sub do
{
	my $self = shift;

	my $all;
	my $raw;
	my $columns;
	my $header_printed = 0;
	GetOptions('columns=s' => \$columns, 'raw' => \$raw, 'all' => \$all, 'noheader' => \$header_printed);

	if ($raw) {
		my @vms = $self->{lxc}->ls();
		foreach my $vm (@vms) {
			print "$vm ";
		}
		print "\n";
		return;
	}

	$all ||= 0;
	$columns ||= $config_reader->get_option_from_main("list", "COLUMNS");

	my @splitted = split(/,/, $columns);

	my @vms_new = $self->get_all_info();
	my %vm_hash;
	my $tmp_string;
	if ($all) {
		foreach my $vm_ref (@vms_new) {
			%vm_hash = %$vm_ref;
			if ($header_printed == 0) {
				foreach my $key (sort keys %vm_hash) {
					$tmp_string = "%".$sizes{$key}."s$sep";
					printf "$tmp_string", "$key";
				}
				print "\n";
				$header_printed = 1;
			}
			foreach my $key (sort keys %vm_hash) {
				printf "%".$sizes{$key}."s$sep", $vm_hash{$key};
			}
			print "\n";
		}
	} else {
		foreach my $vm_ref (@vms_new) {
			%vm_hash = %$vm_ref;
			if ($header_printed == 0) {
				foreach my $key (@splitted) {
					if (defined($vm_hash{$key})) {
						printf "%".$sizes{$key}."s$sep", "$key";
					}
				}
				print "\n";
				$header_printed = 1;
			}
			foreach my $key (@splitted) {
				if (defined($vm_hash{$key})) {
					printf "%".$sizes{$key}."s$sep", $vm_hash{$key};
				}
			}
			print "\n";
		}
	}
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{lxc} = new Lxc::object;
	$self->{helper} = new LxctlHelpers::helper;
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
