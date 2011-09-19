package Lxctl::destroy;

use strict;
use warnings;
use autodie qw(:all);
use Getopt::Long;

use Lxc::object;
use LxctlHelpers::helper;
use Lxctl::set;
use LxctlHelpers::config;
use File::Path;

my %options = ();

my $yaml_conf_dir;
my $lxc_conf_dir;
my $root_mount_path;
my $templates_path;
my $vg;

sub do
{
	my $self = shift;
	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	if ($self->{'lxc'}->status($options{'contname'}) ne 'STOPPED') {
		die "Container $options{'contname'} is running!\n\n";
	}
	GetOptions(\%options, 'force', 'debug', 'configs');

	$self->{'helper'}->fool_proof() if (!$options{force});

	my $old_conf_ref = $self->{'config'}->load_file("$yaml_conf_dir/$options{'contname'}.yaml");
	my %old_conf = %$old_conf_ref;

	$old_conf{'roottype'} ||= 'lvm';
	my $mounted_path = "/dev/$vg/$options{'contname'}";

	if (lc($old_conf{'roottype'}) eq 'file') {
		$mounted_path = "$root_mount_path/$options{'contname'}.raw";
	}

	if (defined($options{'debug'})) {
		foreach my $key (sort keys %old_conf) {
			print "$key = $old_conf{$key}\n";
		}
	}

	$options{'autostart'} = 0;
	my $setter = Lxctl::set->new(%options);
	$setter->set_autostart();

	system("umount $mounted_path");
	if (lc($old_conf{'roottype'}) eq 'file') {
		rmtree("$root_mount_path/$options{'contname'}.raw");
	} elsif (lc($old_conf{'roottype'}) eq 'lvm') {
# HIGHLY EXPERIMENTAL. Seems to be source of some bugs.
#		my $dm_vg = $vg;
#		$dm_vg =~ s/-/--/g;
#		system("dmsetup remove -c $dm_vg-$options{'contname'}");
		system("lvremove -f /dev/$vg/$options{'contname'}");
	}
	rmtree("$root_mount_path/$options{'contname'}");
	rmtree("$lxc_conf_dir/$options{'contname'}");
	if (defined($options{'configs'})) {
		rmtree("$yaml_conf_dir/$options{'contname'}.yaml");
	}
	
	open(my $fstab_file, '<', "/etc/fstab");
	my @fstab = <$fstab_file>;
	close $fstab_file;

	open($fstab_file, '>', "/etc/fstab");

	for my $line (@fstab) {
		$line = "" if $line =~ m#^$mounted_path#xs;
		print $fstab_file $line;
	}

	close $fstab_file;

	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$self->{'helper'} = new LxctlHelpers::helper;
	$self->{'config'} = new LxctlHelpers::config;

	$root_mount_path = $self->{'lxc'}->get_roots_path();
	$yaml_conf_dir = $self->{'lxc'}->get_config_path();
	$lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();
	$vg = $self->{'lxc'}->get_vg();

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
