package Lxctl::destroy;

use strict;
use warnings;
use Getopt::Long;

use Lxc::object;
use Lxctl::helper;
use Lxctl::set;
use Lxctl::_config;

my %options = ();

sub do
{
	my $self = shift;
	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	if ($self->{'lxc'}->status($options{'contname'}) ne 'STOPPED') {
		die "Container $options{'contname'} is running!\n\n";
	}
	GetOptions(\%options, 'force', 'debug');

	$self->{'helper'}->fool_proof() if (!$options{force});

	my $old_conf_ref = $self->{'config'}->load_file("$self->{LXC_CONF_DIR}/$options{'contname'}.yaml");
	my %old_conf = %$old_conf_ref;

	$old_conf{'roottype'} ||= 'lvm';
	my $mounted_path = "/dev/$self->{'VG'}/$options{'contname'}";

	if (lc($old_conf{'roottype'}) eq 'file') {
		$mounted_path = "$self->{'ROOTS_PATH'}/$options{'contname'}.raw";
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
		system("rm -r $self->{'ROOTS_PATH'}/$options{'contname'}.raw");
	} elsif (lc($old_conf{'roottype'}) eq 'lvm') {
		system("echo y | lvremove /dev/$self->{'VG'}/$options{'contname'}");
	}
	system("rm -r $self->{'ROOTS_PATH'}/$options{'contname'}");
	system("rm -r $self->{'LXC_CONF_DIR'}/$options{'contname'}");
	system("rm $self->{'LXC_CONF_DIR'}/$options{'contname'}.yaml");
	
	open(my $fstab_file, '<', "/etc/fstab") or
		die " Failed to open /etc/fstab for reading!\n\n";

	my @fstab = <$fstab_file>;
	close $fstab_file;

	open($fstab_file, '>', "/etc/fstab") or
		die " Failed to open /etc/fstab for writing!\n\n";

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
	$self->{'helper'} = new Lxctl::helper;
	$self->{'config'} = new Lxctl::_config;

	$self->{'ROOTS_PATH'} = $self->{'lxc'}->get_roots_path();
	$self->{'LXC_CONF_DIR'} = $self->{'lxc'}->get_lxc_conf_dir();
	$self->{'VG'} = $self->{'lxc'}->get_vg();

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
