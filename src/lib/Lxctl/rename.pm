package Lxctl::rename;

use strict;
use warnings;

use Lxc::object;

use Getopt::Long;

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

    GetOptions(\%options, 'to=s');

    if ($self->{'lxc'}->status($options{'contname'}) ne 'STOPPED') {
        die "Container $options{'contname'} is running!\n\n";
    }

    if (! defined($options{'to'}) || $options{'to'} eq "") {
        die("You can not rename container to empty name.\n");
    }

    if ($options{'contname'} eq $options{'to'}) {
        die("New name and old one are equal.\n");
    }

    print "Unmounting lvm...\n";
    system("umount /dev/$vg/$options{'contname'}");

    print "Renaming lvm...\n";
    system("lvrename $vg $options{'contname'} $options{'to'}");

    print "Renaming lxctl config...\n";
    system("mv $yaml_conf_dir/$options{'contname'}.yaml $yaml_conf_dir/$options{'to'}.yaml");

    print "Renaming lxc config...\n";
    system("mv $lxc_conf_dir/$options{'contname'} $lxc_conf_dir/$options{'to'}");

    print "Renaming root directory...\n";
    system("mv $root_mount_path/$options{'contname'} $root_mount_path/$options{'to'}");

    print "Changing lxctl config...\n";
    system("sed -i.bak 's/$options{'contname'}/$options{'to'}/g' $yaml_conf_dir/$options{'to'}.yaml");

    print "Changing lxc config...\n";
    system("sed -i.bak 's/$options{'contname'}/$options{'to'}/g' $lxc_conf_dir/$options{'to'}/config");

    return;
}

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->{'lxc'} = new Lxc::object;

    $root_mount_path = $self->{'lxc'}->get_roots_path();
    $templates_path = $self->{'lxc'}->get_template_path();
    $yaml_conf_dir = $self->{'lxc'}->get_config_path();
    $lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();
    $vg = $self->{'lxc'}->get_vg();

    return $self;
}

1;
__END__

=head1 AUTHOR

Pavel Potapenkov, E<lt>ppotapenkov@gmail.comE<gt>
Vladimir Smirnov, E<lt>civil.over@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anatoly Burtsev, Pavel Potapenkov, Vladimir Smirnov

This library is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

=cut
