package Lxctl::vz2lxc;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;

use LxctlHelpers::config;

my %options = ();

my $yaml_conf_dir;
my $lxc_conf_dir;
my $root_mount_path;
my $templates_path;
my $vg;

my $rsync_opts;
my $config;

sub migrate_get_opt
{
	my $self = shift;

	GetOptions(\%options, 'rootsz=s', 'cpus=s', 'cpu-shares=s', 'mem=s', 'io=s', 'fromhost=s', 
		'remuser=s', 'remport=s', 'remname=s', '--continue!' 'afterstart!');

	$options{'remuser'} ||= 'root';
	$options{'remport'} ||= '22';
	$options{'afterstart'} ||= 0;
	$options{'rootsz'} ||= (`echo -n \$(ssh $options{'remuser'}\@$options{'fromhost'} "egrep DISKSPACE /etc/vz/conf/$options{'remname'}.conf | cut -d= -f2 | cut -d: -f1 | cut -d'\\"' -f2")`) . "K";

	defined($options{'remname'})
		or die "You should specify the name of the VZ container!\n\n";

	defined($options{'fromhost'}) or 
		die "To which host shold I migrate?\n\n";
}

sub re_rsync
{
	my $self = shift;

	print "Stopping VZ container $options{'remname'}...\n";
	die "Failed to stop VZ container $options{'remname'}!\n\n"
		if system("ssh $options{'remuser'}\@$options{'fromhost'} vzctl stop $options{'remname'} 1>/dev/null");

	print "Mounting VZ container $options{'remname'}...\n";
	die "Failed to mount VZ container $options{'remname'}!\n\n"
		if system("ssh $options{'remuser'}\@$options{'fromhost'} vzctl mount $options{'remname'} 1>/dev/null");

	print "Re-rsyncing container $options{'contname'}...\n";

	die "Failed to re-rsync root filesystem!\n\n"
		if system("rsync $rsync_opts -e ssh $options{'remuser'}\@$options{'fromhost'}:/var/lib/vz/root/$options{'remname'}/ $root_mount_path/$options{'contname'}/rootfs/ 1>/dev/null");

	print "Unmounting VZ container $options{'remname'}...\n";
	die "Failed to unmount VZ container $options{'remname'}!\n\n"
		if system("ssh $options{'remuser'}\@$options{'fromhost'} vzctl umount $options{'remname'} 1>/dev/null");

}

sub vz_migrate
{
	my $self = shift;

	$rsync_opts = $config->get_option_from_main('rsync', 'RSYNC_OPTS');
	$rsync_opts ||= "-aH --delete --numeric-ids --exclude 'proc/*' --exclude 'sys/*'";

	die "Failed to create container!\n\n"
		if system("lxctl create $options{'contname'} --empty --rootsz $options{'rootsz'} --save");

	print "Rsync'ing VZ container...\n";

	print "There were some errors during rsyncing root filesystem. It's definetely NOT okay if it was the only rsync pass.\n\n"
		if system("rsync $rsync_opts -e ssh $options{'remuser'}\@$options{'fromhost'}:/var/lib/vz/root/$options{'remname'}/ $root_mount_path/$options{'contname'}/rootfs/ 1>/dev/null");

	$self->re_rsync();

	if ($options{'afterstart'} != 0) {
		die "Failed to start container $options{'contname'}!\n\n"
			if system("lxctl start $options{'contname'}");
	}
}

sub migrate_configuration
{
	my $self = shift;

	die "Failed to migrate MTU!\n\n"
		if system("lxctl set $options{'contname'} --mtu \$(ssh $options{'remuser'}\@$options{'fromhost'} \"sed -n 's/^[\\t ]\\+mtu[\\t ]\\+\\([0-9]\\+\\)/\\1/p' /var/lib/vz/private/$options{'remname'}/etc/network/interfaces | awk '{print \$2}'\")");
}

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	$self->migrate_get_opt();
	$self->vz_migrate();
	$self->migrate_configuration();
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->{lxc} = new Lxc::object;
	$root_mount_path = $self->{'lxc'}->get_roots_path();
	$templates_path = $self->{'lxc'}->get_template_path();
	$yaml_conf_dir = $self->{'lxc'}->get_config_path();
	$lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();
	$vg = $self->{'lxc'}->get_vg();

	$config = new LxctlHelpers::config;
	return $self;
}

1;
__END__
=head1 NAME

Lxctl::vzmigrate

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
