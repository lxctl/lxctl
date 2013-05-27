package Lxctl::stop;

use strict;
use warnings;

use Lxc::object;
use LxctlHelpers::config;
use File::Path;

my $config = new LxctlHelpers::config;

my $yaml_conf_dir;
my $lxc;
my %options = ();
my $root_path;

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	my $vm_option_ref;
	my %vm_options;
	$vm_option_ref = $config->load_file("$yaml_conf_dir/$options{'contname'}.yaml");
	%vm_options = %$vm_option_ref;

	my @mount_points;
	my $mount_result = `mount`;

	if (defined $vm_options{'mountpoints'}) { 
                my $mount_ref = $vm_options{'mountpoints'};

                @mount_points = @$mount_ref;
                if ($#mount_points == -1 ) {
                        #print "No mount points specified!\n";
                        last;
                }

                foreach my $mp_ref (@mount_points) {
                        my %mp = %$mp_ref;
                        my $cmd = "umount";
                        my $to = quotemeta("$root_path/$options{'contname'}/rootfs$mp{'to'}");

                        if ($mount_result =~ /on $to/) {
				$cmd .= " $to";
				system("$cmd");
				if ( $? != 0 ) {
					print "Can't umount $mp{'to'} !";
				}
			}
                }
	}

	if (defined $vm_options{'rootfs_mp'}{'to'}) {
		my $cmd = "umount $vm_options{'rootfs_mp'}{'to'}";
		system("$cmd");
		if ( $? != 0 ) {
			print "Can't umount $vm_options{'rootfs_mp'}{'to'} !";
		} 
	}

	eval {
		$self->{'lxc'}->stop($options{'contname'});
		print "It seems that \"$options{'contname'}\" is stopped now\n";
	} or do {
		print "$@";
		die "Cannot stop $options{'contname'}!\n\n";
	};

	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	
	$lxc = Lxc::object->new;
	$self->{'lxc'} = Lxc::object->new;
	$yaml_conf_dir = $lxc->get_yaml_config_path();
	$root_path = $lxc->get_root_mount_path();

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
