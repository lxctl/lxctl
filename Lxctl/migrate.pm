package Lxctl::migrate;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;

use Lxctl::_config;

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

	GetOptions(\%options, 'ipadd|ipaddr=s', 'hostname=s', 'userpasswd=s', 
		'onboot=s', 'nameserver=s', 'searchdomain=s', 'rootsz=s', 
		'netmask|mask=s', 'defgw|gw=s', 'dns=s', 'cpu=s', 'mem=s', 
		'io=s', 'tohost=s', 'remuser=s', 'remport=s', 'remname=s',
		'clone', 'afterstart!');

	$options{'remuser'} ||= 'root';
	$options{'remport'} ||= '22';
	$options{'remname'} ||= $options{'contname'};
	$options{'afterstart'} ||= 0;
}

sub re_rsync
{
	my $self = shift;
	my $status;

	eval {
		$status = $self->{'lxc'}->status($options{'contname'});
	} or do {
		die "Failed to get status for container $options{'contname'}!\n\n";
	};

	return if $status ne 'RUNNING';

	eval {
		if ($options{'clone'}) {
			print "Freezing container $options{'contname'}...\n";
			$self->{'lxc'}->freeze($options{'contname'});
		} else {
			print "Stopping container $options{'contname'}...\n";
			$self->{'lxc'}->stop($options{'contname'});
		}
	} or do {
		if ($options{'clone'}) {
			die "Failed to freeze container $options{'contname'}!\n\n";
		} else {
			die "Failed to stop container $options{'contname'}!\n\n";
		}
	};

	print "Re-rsyncing container $options{'contname'}...\n";

	die "Failed to re-rsync root filesystem!\n\n"
		if system("rsync -avz -e ssh $root_mount_path/$options{'contname'}/ $options{'remuser'}\@$options{'tohost'}:$root_mount_path/$options{'remname'}/");

	eval {
		if ($options{'clone'}) {
			print "Unfreezing container $options{'contname'}...\n";
			$self->{'lxc'}->unfreeze($options{'contname'});
		}
	} or do {
		if ($options{'clone'}) {
			die "Failed to unfreeze container $options{'contname'}!\n\n";
		}
	};
}

sub copy_config
{
	my $self = shift;

	print "Configuring $options{'remname'}...\n";

	my $tmp = $config->load_file("$yaml_conf_dir/$options{'remname'}.yaml");
	my %conf_hash = %$tmp;

	my $set = "lxctl set $options{'remname'}";

	for my $key (sort keys %options) {
		$conf_hash{$key} = $options{$key};
	}

	for my $key (sort keys %conf_hash) {
		$set = "$set --$key '$conf_hash{$key}'" if defined($conf_hash{$key});
	}

	die "Failed to configure remote container!\n\n"
		if system("ssh $options{'remuser'}\@$options{'tohost'} \"$set\"");
}

sub remote_deploy
{
	my $self = shift;

	$rsync_opts = $config->get_option_from_main('rsync', 'RSYNC_OPTS');
	$rsync_opts ||= '-avz';

	defined($options{'tohost'}) or 
		die "To which host shold I migrate?\n\n";

	die "Failed to create container!\n\n"
		if system("ssh $options{'remuser'}\@$options{'tohost'} 'lxctl create $options{'remname'} --empty --save'");

	die "Failed to rsync root filesystem!\n\n"
		if system("rsync $rsync_opts -e ssh $root_mount_path/$options{'contname'}/ $options{'remuser'}\@$options{'tohost'}:$root_mount_path/$options{'remname'}/");

	$self->re_rsync();

	$self->copy_config();

	if ($options{'afterstart'} != 0) {
		die "Failed to start remote container!\n\n"
			if system("ssh $options{'remuser'}\@$options{'tohost'} \"lxctl start $options{'remname'}\"");
	}
}

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	$self->migrate_get_opt();
	$self->remote_deploy();
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
	$config = new Lxctl::_config;
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
