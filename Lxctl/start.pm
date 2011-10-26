package Lxctl::start;

use strict;
use warnings;

use Lxc::object;
use LxctlHelpers::config;
use File::Path;

my $config = new LxctlHelpers::config;

my %options = ();

my $yaml_conf_dir;
my $contname;
my $root_path;
my $lxc;
my $lxc_conf_dir;
my $lxc_log_path;
my $lxc_log_level;

sub _actual_start
{
	my ($self, $daemon) = @_;
	my $lxc_real_log_path = $lxc_log_path;
	$lxc_real_log_path =~ s/%CONTNAME%/$contname/g;
	$lxc->start($contname, $daemon, $lxc_conf_dir."/".$contname."/config", $lxc_real_log_path, $lxc_log_level);
}

# At 0.3.0 we mount root from config at start. Make shure we have it there, not in fstab.
sub check_root_in_config
{
	my ($self, %vm_options) = @_;

	if (defined($vm_options{'api_ver'}) && $vm_options{'api_ver'} == $config->get_api_ver()) {
		die "$yaml_conf_dir/$contname.yaml has API version $vm_options{'api_ver'} (and current is ".$config->get_api_ver().") and has no root_mp statement. Fix it.\n\n";
	}

	$vm_options{'api_ver'} = $config->get_api_ver();

	open(my $fstab, '<', '/etc/fstab');
	my @mpoints = <$fstab>;
	close $fstab;

	my $vg = $lxc->get_vg();
	for my $mp (@mpoints) {
		next if !($mp =~ m/^\/dev\/$vg\/$vm_options{'contname'}/);

		my @fstab_line = split (/\s+/, $mp);
		my %root_mp = ('from' => $fstab_line[0], 'to' => $fstab_line[1], 'fs' => $fstab_line[2], 'opts' => $fstab_line[3]);

		$vm_options{'rootfs_mp'} = \%root_mp;
		$config->change_hash(\%vm_options, "$yaml_conf_dir/$contname.yaml");

		chomp $mp;
		use Term::ANSIColor;
		print color "bold red";
		print "Removing $mp from /etc/fstab.\nCHECK IT! Backup will be saved at /etc/fstab.bak.\n\n";
		print color "reset";
		system("sed -i.bak 's#$mp##' /etc/fstab");

		return \%root_mp;
	}

	die "There is no root mount directions at $yaml_conf_dir/$contname.yaml and I failed to find them in /etc/fstab.\n\n";
}

sub do
{
	my $self = shift;

	$contname = shift
		or die "Name the container please!\n\n";

	my $vm_option_ref;
	my %vm_options;
	$vm_option_ref = $config->load_file("$yaml_conf_dir/$contname.yaml");
	%vm_options = %$vm_option_ref;

	my @mount_points;
	my $mount_result = `mount`;
	# mount root
	if (!defined($vm_options{'rootsz'}) || $vm_options{'rootsz'} ne 'share') {
		my $mp_ref = $vm_options{'rootfs_mp'};
		$mp_ref = $self->check_root_in_config(%vm_options) if (!defined($mp_ref));
		my %mp = %$mp_ref;
#		print "\n\n\nDEBUG: $mount_result\n$mp{'to'}\n\n\n";
#		print "TRUE\n" if ($mount_result !~ m/^$mp{'from'}/); 
		if ($mount_result !~ m/on $mp{'to'}/) {
			(system("mount -t $mp{'fs'} -o $mp{'opts'} $mp{'from'} $mp{'to'}") == 0) or die "Failed to mount $mp{'from'} to $mp{'to'}\n\n";
		}
	}
	
	if (defined $vm_options{'mountpoints'}) { {
		my $mount_ref = $vm_options{'mountpoints'};

		@mount_points = @$mount_ref;
		if ($#mount_points == -1 ) {
			#print "No mount points specified!\n";
			last;
		}

		#TODO: Move to mount module.
		foreach my $mp_ref (@mount_points) {
			my %mp = %$mp_ref;
			my $cmd = "mount";
			my $to = quotemeta("$root_path/$contname/rootfs$mp{'to'}");
			
			next if ($mount_result =~ /on $to/);
			if (defined($mp{'fs'})) {
				$cmd .= " -t $mp{'fs'}";
			}
			mkpath("$to") if (! -e "$to");
			$cmd .= " -o $mp{'opts'} $mp{'from'} $to";
			system("$cmd");
		}
	} } else {
		print "No mount points specified!\n";
	}

	eval {
		$self->_actual_start(1);
		sleep(1);
		my $status = $lxc->status($contname);
		if ($status eq "STOPPED") {
			$self->_actual_start(0);
		}
		print "It seems that \"$contname\" was started.\n";
	} or do {
		print "$@";
		# We should check $@ to analyize some common errors, such as:
		# 1) No cgroups mounter
		# 2) if it tries to mount proc to /usr/lib/lxc//proc - it's usualy forgotten /proc in container's rootfs. Check same for dev and sys
		# 3) ... Maybe more in future.
		die "Cannot start $contname!\n\n";
	};
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$lxc = Lxc::object->new;
	$yaml_conf_dir = $lxc->get_yaml_config_path();
	$lxc_conf_dir = $lxc->get_lxc_conf_dir();
	$root_path = $lxc->get_root_mount_path();
	$lxc_log_path = $lxc->get_lxc_log_path();
	$lxc_log_level = $lxc->get_lxc_log_level();

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
