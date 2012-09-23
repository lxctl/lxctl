package Lxctl::Core::VirtualMachine::System::Root::LVM;

use strict;
use Lxctl::Core::VirtualMachine::System::Root;

our @ISA = qw(Lxctl::Core::VirtualMachine::System::Root);

sub createRoot
{
    my $self = shift;

    $self->commit();

    my $fs_type = $self->getFsType();
    my $mkfs_opts = $self->getMkfsOpts();
    my $root_size = $self->getRootSize();
    my $lvm_vg = $self->getLvmVg();
    my $root_location = $self->getRootLocation();
    my $hostname = $root_location;
    $root_location =~ s/^.*\/([^\/]+)$/$1/;

    system("lvcreate -L $root_size -n $hostname $lvm_vg") == 0
        or die "Failed to create LVM '$root_location' [$?]\n";
    system("yes | mkfs.$fs_type $root_location $mkfs_opts") == 0
        or die "Failed to create filesystem '$fs_type' at '$root_location' [$?]\n";
}

sub destroyRoot
{
    my $self = shift;

    $self->commit();

    $self->unmountRoot();

    my $root_location = $self->getRootLocation();
    system("lvremove '$root_location'") == 0
        or die "Failed to remove LVM '$root_location' [$?]\n";
}

sub extendRoot
{
    my $self = shift;

    $self->commit();

    my $root_location = $self->getRootLocation();
    my $new_size = $self->getRootSize();
    my $fs_type = $self->getFsType();
    $fs_type =~ /^ext[234]$/
        or die "Resize of filesystems other then ext family is not supported. Yet.\n";

    system("lvextend -L '$new_size' '$root_location'") == 0
        or die "Failed to extend LVM '$root_location' [$?]\n";

    if ($fs_type =~ /^ext[234]$/) {
        system("resize2fs '$root_location'") == 0
            or die "Failed to extend filesystem '$fs_type' at '$root_location' [$?]\n";
    }
}

sub reduceRoot
{
    my $self = shift;

    die "Reducing size of LVM root type is not supported. Yet.\n";
}

sub resizeRoot
{
    my $self = shift;

    $self->commit();

    my $new_size = $self->getRootSize();
    my $old_size = $self->getActualRootSize();

    if ($new_size == $old_size) {
        die "Will not resize to the same size\n";
    } elsif ($new_size < $old_size) {
        $self->reduceRoot();
    } else {
        $self->extendRoot();
    }
}

sub getActualRootSize
{
    my $self = shift;

    my $root_location = $self->getRootLocation();
    open(my $lv_info, "lvdisplay --units b '$root_location'|")
        or die "Failed to get stats of LVM '$root_location'\n";
    while (<$lv_info>) {
        /^\s+LV\s+Size\s+([0-9]+)\s+B\s*$/ and return $1;
    }
    die "Failed to get stats of LVM '$root_location'\n";
}

1;
