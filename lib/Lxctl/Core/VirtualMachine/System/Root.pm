package Lxctl::Core::VirtualMachine::System::Root;

use strict;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $hostname) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    # 'static' for hardcoded superdefault value
    my $self = {
        'fs_type' =>         { 'conf' => $$conf{'fs_type'},         'default' => $$defaults{'fs_type'},     'static' => 'ext4' },
        'mnt_fs_opts' =>     { 'conf' => $$conf{'mnt_fs_opts'},     'default' => $$defaults{'mnt_fs_opts'}, 'static' => 'defaults,barrier=0,noatime' },
        'mkfs_opts' =>       { 'conf' => $$conf{'mkfs_opts'},       'default' => $$defaults{'mkfs_opts'},   'static' => '-b 4096' },
        'root_size' =>       { 'conf' => $$conf{'root_size'},       'default' => $$defaults{'root_size'},   'static' => 53687091200 },
        'root_type' =>       { 'conf' => $$conf{'root_type'},       'default' => $$defaults{'root_type'},   'static' => 'lvm' },
        'lvm_vg' =>          { 'conf' => $$conf{'lvm_vg'},          'default' => $$defaults{'lvm_vg'},      'static' => 'vg00' },
        'file_path' =>       { 'conf' => $$conf{'file_path'},       'default' => $$defaults{'file_path'},   'static' => '/var/lib/lxctl/root_files/' },
        'mount_point' =>     { 'conf' => $$conf{'mount_point'},     'default' => $$defaults{'mount_point'} },
        'root_location' =>   { 'conf' => $$conf{'root_location'},   'default' => $$defaults{'root_location'} }
    };
    $$self{'hostname'} = $hostname;

    bless $self, $class;
    return $self;
}

sub commit
{
    my $self = shift;

    # fs_type: should be ext*, xfs or reiserfs
    $$self{'fs_type'} = $self->getFsType();
    my $fs_type = $$self{'fs_type'};
    $fs_type =~ /^(ext[234])|xfs|reiserfs$/
        or die "fs_type should be ext*, xfs or reiserfs\n";

    # mnt_fs_opts: should look like mountoptions from fstab
    my $mnt_fs_opts = $self->getMntFsOpts();
    $mnt_fs_opts =~ /^([a-z]+(=[0-9a-z]+),)*[a-z]+(=[0-9a-z]+)$/
        or die "'$mnt_fs_opts' is not valid FS mount options\n";

    # mkfs_opts: shoud not inject commandline
    my $mkfs_opts = $self->getMntFsOpts();
    my $valid = 1;
    $valid = 0 if $mkfs_opts =~ /[';]/;
    $valid or die "Symbols \"'\" and ';' are not allowed in mkfs_opts\n";

    # root_type: should be lvm, file or shared
    $$self{'root_type'} = $self->getRootType();
    my $root_type = $$self{'root_type'};
    $root_type =~ /^(lvm|file|shared)$/
        or die "root_type should be lvm, file or shared\n";

    # root_size: should be positive integer
    $$self{'root_size'} = $self->getRootSize();
    my $root_size = $$self{'root_size'};
    $root_size > 0
        or die "root_size should be positive integer\n";

    # lvm_vg: should non inject commandline
    my $lvm_vg = $self->getLvmVg();
    $lvm_vg =~ /^[^';]+$/
        or die "lvm_vg should not contain symbols \"'\" and ';'";

    # file_path: should be absolute path and should not inject commandline
    $$self{'file_path'} = $self->getMountPoint();
    my $file_path = $$self{'file_path'};
    $file_path =~ /^\//
        or "file_path should be absolute path\n";
    $file_path =~ /^[^';]+$/
        or die "file_path should not contain symbols \"'\" and ';'";

    # mount_point: should be absolute path and should not inject commandline
    $$self{'mount_point'} = $self->getMountPoint();
    my $mount_point = $$self{'mount_point'};
    $mount_point =~ /^\//
        or "mount_point should be absolute path\n";
    $mount_point =~ /^[^';]+$/
        or die "mount_point should not contain symbols \"'\" and ';'";

    # root_location: should be absolute path and should not inject commandline
    $$self{'root_location'} = $self->getRootLocation();
    my $root_location = $$self{'root_location'};
    $root_location =~ /^\// or $self->getRootType() eq 'shared'
        or "root_location should be absolute path\n";
    $root_location =~ /^[^';]+$/
        or die "root_location should not contain symbols \"'\" and ';'";
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = {};
    $$dump{'fs_type'} = $$self->{'fs_type'}->{'conf'};
    $$dump{'mnt_fs_opts'} = $$self->{'mnt_fs_opts'}->{'conf'};
    $$dump{'mkfs_opts'} = $$self->{'mkfs_opts'}->{'conf'};
    $$dump{'root_size'} = $$self->{'root_size'}->{'conf'};
    $$dump{'root_type'} = $$self->{'root_type'}->{'conf'};
    $$dump{'mount_point'} = $$self->{'mount_point'}->{'conf'};
    $$dump{'root_location'} = $$self->{'root_location'}->{'conf'};

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";
    $conf .= "lxc.rootfs = " . $self->getMountPoint() . "\n";

    return $conf;
}

sub rootExists
{
    my $self = shift;

    return (-e $self->getRootLocation() ? 1 : 0);
}

sub mountRoot
{
    my $self = shift;

    $self->commit();

    my $root_location = $self->getRootLocation();
    my $mount_point = $self->getMountPoint();
    my $fs_type = $self->getFsType();
    my $mnt_fs_opts = $self->getMntFsOpts();

    $self->rootExists()
        or die "There is no root filesystem at " . $root_location . "\n";

    -e $mount_point or mkdir $mount_point
        or die "Failed to create mount_point directory at $mount_point\n";

    -d $mount_point
        or die "mount_point $mount_point is not a directory\n";

    system("mount -t '$fs_type' -o '$mnt_fs_opts' '$root_location' '$mount_point'") == 0
        or die "Failed to mount $root_location to $mount_point [$?]\n";
}

sub unmountRoot
{
    my $self = shift;

    $self->commit();

    my $root_location = $self->getRootLocation();
    system("umount '$root_location'") == 0
            or die "Failed to unmount $root_location [$?]\n";
}

sub createRoot
{
    my $self = shift;
}

sub destroyRoot
{
    my $self = shift;
}

sub resizeRoot
{
    my $self = shift;
}

sub getFsType
{
    my $self = shift;

    if (defined($$self{'fs_type'}->{'conf'})) {
        return $$self{'fs_type'}->{'conf'};
    } elsif (defined($$self{'fs_type'}->{'default'})) {
        return $$self{'fs_type'}->{'default'};
    }
    return $$self{'fs_type'}->{'static'};
}

sub getMntFsOpts
{
    my $self = shift;

    if (defined($$self{'mnt_fs_opts'}->{'conf'})) {
        return $$self{'mnt_fs_opts'}->{'conf'};
    } elsif (defined($$self{'mnt_fs_opts'}->{'default'})) {
        return $$self{'mnt_fs_opts'}->{'default'};
    }
    return $$self{'mnt_fs_opts'}->{'static'};
}

sub getMkfsOpts
{
    my $self = shift;

    if (defined($$self{'mkfs_opts'}->{'conf'})) {
        return $$self{'mkfs_opts'}->{'conf'};
    } elsif (defined($$self{'mkfs_opts'}->{'default'})) {
        return $$self{'mkfs_opts'}->{'default'};
    }
    return $$self{'mkfs_opts'}->{'static'};
}

sub getRootType
{
    my $self = shift;

    if (defined($$self{'root_type'}->{'conf'})) {
        return $$self{'root_type'}->{'conf'};
    } elsif (defined($$self{'root_type'}->{'default'})) {
        return $$self{'root_type'}->{'default'};
    }
    return $$self{'root_type'}->{'static'};
}

sub getRootSize
{
    my $self = shift;

    if (defined($$self{'root_size'}->{'conf'})) {
        return $$self{'root_size'}->{'conf'};
    } elsif (defined($$self{'root_size'}->{'default'})) {
        return $$self{'root_size'}->{'default'};
    }
    return $$self{'root_size'}->{'static'};
}

sub getLvmVg
{
    my $self = shift;

    if (defined($$self{'lvm_vg'}->{'conf'})) {
        return $$self{'lvm_vg'}->{'conf'};
    } elsif (defined($$self{'lvm_vg'}->{'default'})) {
        return $$self{'lvm_vg'}->{'default'};
    }
    return $$self{'lvm_vg'}->{'static'};
}

sub getFilePath
{
    my $self = shift;

    if (defined($$self{'file_path'}->{'conf'})) {
        return $$self{'file_path'}->{'conf'};
    } elsif (defined($$self{'file_path'}->{'default'})) {
        return $$self{'file_path'}->{'default'};
    }
    return $$self{'file_path'}->{'static'};
}

sub getMountPoint
{
    my $self = shift;

    if (defined($$self{'mount_point'}->{'conf'})) {
        return $$self{'mount_point'}->{'conf'};
    } elsif (defined($$self{'mount_point'}->{'default'})) {
        return $$self{'mount_point'}->{'default'};
    }
    return;
}

sub getRootLocation
{
    my $self = shift;

    if (defined($$self{'root_location'}->{'conf'})) {
        return $$self{'root_location'}->{'conf'};
    } elsif (defined($$self{'root_location'}->{'default'})) {
        return $$self{'root_location'}->{'default'};
    }
    return;
}

sub setFsType
{
    my ($self, $value) = @_;
    $$self{'fs_type'}->{'conf'} = $value;
}

sub setMntFsOpts
{
    my ($self, $value) = @_;
    $$self{'mnt_fs_opts'}->{'conf'} = $value;
}

sub setMkfsOpts
{
    my ($self, $value) = @_;
    $$self{'mkfs_opts'}->{'conf'} = $value;
}

sub setRootType
{
    my ($self, $value) = @_;
    $$self{'root_type'}->{'conf'} = $value;
}

sub setLvmVg
{
    my ($self, $value) = @_;
    $$self{'lvm_vg'}->{'conf'} = $value;
}

sub setFilePath
{
    my ($self, $value) = @_;
    $$self{'file_path'}->{'conf'} = $value;
}

sub setRootSize
{
    my ($self, $value) = @_;
    $$self{'root_size'}->{'conf'} = $value;
}

sub setMountPoint
{
    my ($self, $value) = @_;
    $$self{'mount_point'}->{'conf'} = $value;
}

sub setRootLocation
{
    my ($self, $value) = @_;
    $$self{'root_location'}->{'conf'} = $value;
}

1;
