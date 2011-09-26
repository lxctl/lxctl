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

sub _actual_start
{
	my ($self, $daemon) = @_;
	$lxc->start($contname, $daemon, $lxc_conf_dir."/".$contname."/config");
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
	my $mp_ref = $vm_options{'rootfs_mp'};
	my %mp = %$mp_ref;
	print "\n\n\nDEBUG: $mount_result\n$mp{'to'}\n\n\n";
	print "TRUE\n" if ($mount_result !~ m/^$mp{'from'}/); 
	system("mount -t $mp{'fs'} -o $mp{'opts'} $mp{'from'} $mp{'to'}") if ($mount_result !~ m/on $mp{'to'}/);
	if (defined $vm_options{'mountpoints'}) {
		my $mount_ref = $vm_options{'mountpoints'};

		@mount_points = @$mount_ref;
		if ($#mount_points == -1 ) {
			print "No mount points specified!\n";
			break;
		}

		#TODO: Move to mount module.
		foreach my $mp_ref (@mount_points) {
			%mp = %$mp_ref;
			my $cmd = "mount";

			next if ($mount_result =~ m/^on $mp{'to'}/);
			if (defined($mp{'fs'})) {
				$cmd .= " -t $mp{'fs'}";
			}
			mkpath("$root_path/$contname/rootfs/$mp{'to'}") if (! -e "$root_path/$contname/rootfs/$mp{'to'}");
			$cmd .= " -o $mp{'opts'} $mp{'from'} $root_path/$contname/rootfs/$mp{'to'}";
			system("$cmd");
		}
	} else {
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
	$root_path = $lxc->get_root_mount_path;

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
