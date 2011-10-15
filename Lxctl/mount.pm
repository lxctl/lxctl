package Lxctl::mount;

use strict;
use warnings;
use autodie qw(:all);

use Lxc::object;
use LxctlHelpers::config;
use Getopt::Long;
use File::Path;
use List::Util qw[max];

my %options = ();

my $yaml_conf_dir;
my $lxc;
my $config = new LxctlHelpers::config;
my $contname;
my $root_path;

sub add
{
	my $self = shift;
	$Getopt::Long::passthrough = 1;

	GetOptions(\%options, 'from=s', 'to=s', 'mountoptions=s', 'fs=s');

	$options{'from'} || die "Don't know what to mount.\n\n";
	$options{'to'} || die "Don't know where to mount.\n\n";

	-e $options{'from'} || die "You are trying to mount void. Lxctl does not able to do it. Yet.\n\n";

	if (!defined($options{'mountoptions'})) {
		print "No options specified, using telepathy...\n";
		if ( -d $options{'from'} ) {
			$options{'mountoptions'} = "bind";
		} elsif ( -e $options{'from'} ) {
			$options{'mountoptions'} = "noatime";
		}
	}

	if ($lxc->status($contname) eq "RUNNING") {
		my $cmd = "mount";
		$cmd .= " -t $options{'fs'}" if defined($options{'fs'});
		mkpath("$root_path/$contname/rootfs/$options{'to'}") if (! -e "$root_path/$contname/rootfs/$options{'to'}");
		$cmd .= " -o $options{'mountoptions'} $options{'from'} $root_path/$contname/rootfs/$options{'to'}";
		system("$cmd");
	}

	my $vm_option_ref;
	my %vm_options;
	$vm_option_ref = $config->load_file("$yaml_conf_dir/$contname.yaml");
	%vm_options = %$vm_option_ref;

	my @mount_points;
	if (defined $vm_options{'mountpoints'}) {
		my $mount_ref = $vm_options{'mountpoints'};
		@mount_points = @$mount_ref;
	}

	push (@mount_points, \%options);

	$vm_options{'mountpoints'} = \@mount_points;

	$config->save_hash(\%vm_options, "$yaml_conf_dir/$contname.yaml");

	return;
}

sub list
{
	my $self = shift;
	my $vm_option_ref;
	my %vm_options;
	$vm_option_ref = $config->load_file("$yaml_conf_dir/$contname.yaml");
	%vm_options = %$vm_option_ref;

	my @mount_points;
	if (defined $vm_options{'mountpoints'}) {
		my $mount_ref = $vm_options{'mountpoints'};
		@mount_points = @$mount_ref;
	} else {
		print "No mountpoints\n";
		return;
	}

	if ($#mount_points) {
		print "No mountpoints\n";
		return;
	}

	my %mp;
	my $columns = "id,from,to,fs,mountoptions";
	my %sizes;
	my $id_size = @mount_points;
	$sizes{'fs'} = length("auto");
	$sizes{'id'} = max(length("$id_size"), length("id"));
	my $sep = "  ";
	foreach my $mp_ref (@mount_points) {
		%mp = %$mp_ref;
		foreach my $key (split(/,/, $columns)) {
			if (defined($mp{$key}) && (!defined($sizes{$key}) || $sizes{$key} < length($mp{$key}))) {
				$sizes{$key} = length($mp{$key});
			}
		}
	}

	foreach my $key (split(/,/, $columns)) {
		printf "%".$sizes{$key}."s$sep", $key;
	}
	print "\n";

	my $cnt = 0;
	foreach my $mp_ref (@mount_points) {
		%mp = %$mp_ref;
		$cnt++;
		foreach my $key (split(/,/, $columns)) {
			$mp{'id'} = $cnt;
			if ($key eq "fs" && !defined($mp{$key})) {
				$mp{$key} = "auto";
			}
			printf "%".$sizes{$key}."s$sep", $mp{$key};
		}
		print "\n";
	}

	return;
}

sub del
{
	my $self = shift;
	my $id;
	$Getopt::Long::passthrough = 1;
	GetOptions('id=i' => \$id);

	die "No id specified, don't know what to delete.\n\n" if !defined($id);

	my $vm_option_ref;
	my %vm_options;
	$vm_option_ref = $config->load_file("$yaml_conf_dir/$contname.yaml");
	%vm_options = %$vm_option_ref;

	my @mount_points;
	if (defined $vm_options{'mountpoints'}) {
		my $mount_ref = $vm_options{'mountpoints'};
		@mount_points = @$mount_ref;
	} else {
		print "Nothing to delete\n";
		return;
	}

	my @new_array;
	my $cnt = 0;
	foreach my $val (@mount_points) {
		$cnt++;
		if ($cnt != $id) {
			push(@new_array, $val)
		} elsif ($lxc->status($contname) eq "RUNNING") {
			my %mount = %$val;
			my $cmd = "umount -r -f $root_path/$contname/rootfs/$mount{'to'}";
			eval {
				system("$cmd");
			} or do {
				print "There was a problem while umounting: $@\n";
			}
		}
	}

	$vm_options{'mountpoints'} = \@new_array;

	$config->save_hash(\%vm_options, "$yaml_conf_dir/$contname.yaml");

}

sub do
{
	my $self = shift;
	$contname = shift
		or die "Name the container please!\n\n";

	$Getopt::Long::passthrough = 1;

	my $del;
	my $add;
	my $list;
	GetOptions('add' => \$add, 'del' => \$del, 'list' => \$list);

	my $opts = 0;
	$opts += 1 if $add;
	$opts += 1 if $del;
	$opts += 1 if $list;
	die "No action options specified. Avaliable: --add, --list or --del.\n\n" if $opts < 1;
	die "Specify only ONE of --add, --list or --del.\n\n" if $opts > 1;

	$self->add() if $add;
	$self->del() if $del;
	$self->list() if $list;
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$lxc =  Lxc::object->new;
	$yaml_conf_dir = $lxc->get_yaml_config_path();
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
