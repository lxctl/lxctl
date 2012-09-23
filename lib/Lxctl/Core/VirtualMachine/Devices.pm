package Lxctl::Core::VirtualMachine::Devices;

use strict;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $cgroup_path, $cgroup_name) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    # 'static' is hardcoded superdefauld value
    my $self = {
        'device_policy' => { 'conf' => $$conf{'device_policy'},   'default' => $$defaults{'device_policy'},   'static' => 'deny' },
        'devices'   => { 'conf' => $$conf{'devices'},   'default' => $$defaults{'devices'},   'static' => ['c 1:3 rwm', 'c 1:5 rwm', 
            'c 5:1 rwm', 'c 5:0 rwm', 'c 4:0 rwm', 'c 4:1 rwm', 'c 1:9 rwm', 'c 1:8 rwm', 'c 136:* rwm', 'c 5:2 rwm', 'c 254:0 rwm'] }
    };
    $$self{'cgroup_path'} = $cgroup_path;
    $$self{'cgroup_name'} = $cgroup_name;

    bless $self, $class;
    return $self;
}

sub commit
{
    my $self = shift;

    # device_policy: allow or deny devices by default
    my $device_policy = $self->getDevicePolicy();
    $device_policy eq 'allow' or $device_policy eq 'deny'
        or die "device_policy parameter shoul be 'allow' or 'deny'\n";

    # devices: should be a list of devises types, numbers and desired rights
    my $devices = $self->getDevices();
    for my $dev (@$devices) {
        $dev =~ /^[cb]\s+([0-9]+|\*):([0-9]+|\*)\s+[rwm]{3}$/
            or die "'$dev' is not correct device specification\n";
    }
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = {'device_policy' => $self->getDevicePolicy(), 'devices' => $self->getDevices()};

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";
    my $action = "";

    my $device_policy = $self->getDevicePolicy();
    if ($device_policy eq 'deny') {
        $conf .= "lxc.cgroup.devices.deny = a\n";
        $action = 'allow';
    } else {
        $conf .= "lxc.cgroup.devices.allow = a\n";
        $action = 'deny';
    }

    for my $dev (@{$self->getDevices()}) {
        $dev = $self->parseDeviceName($dev);
        $conf .= "lxc.cgroup.devices.$action = $dev\n";
    }

    return $conf;
}

sub parseDeviceName
{
    my ($self, $device) = @_;
    $device =~ s/^\s+//;
    $device =~ s/\s+$//;
    $device =~ s/\s+/ /;
    return $device;
}

sub allowOrDenyDevice
{
    my ($self, $device, $action) = @_;
    my $file = "$$self{'cgroup_path'}/$$self{'cgroup_name'}/devices.$action";
    open my $cgrp_dev_allow, ">$file"
        or die "Failed to open $file for writing\n";
    print $cgrp_dev_allow $self->parseDeviceName($device) . "\n";
    close $cgrp_dev_allow;
}

sub addDevice
{
    my ($self, $device) = @_;

    $device = $self->parseDeviceName($device);
    for my $dev (@{$self->getDevices()}) {
        $dev = $self->parseDeviceName($dev);
        $dev ne $device
            or die "Device '$dev' already in the list\n";
    }

    push @{$self->getDevices()}, $device;

    if ($self->getDevicePolicy() eq 'deny') {
        $self->allowOrDenyDevice($device, 'allow');
    } else {
        $self->allowOrDenyDevice($device, 'deny');
    }
}

sub deleteDevice
{
    my ($self, $device) = @_;

    my $found = 0;
    $device = $self->parseDeviceName($device);
    my @new_devices;
    for my $dev (@{$self->getDevices()}) {
        $dev = $self->parseDeviceName($dev);
        if ($dev ne $device) {
            push @new_devices, $device;
        } else {
            $found = 1;
        }
    }

    $found or die "There is no device '$device' in the list\n";
    $self->setDevices(\@new_devices);

    if ($self->getDevicePolicy() eq 'deny') {
        $self->allowOrDenyDevice($device, 'deny');
    } else {
        $self->allowOrDenyDevice($device, 'allow');
    }
}

sub getDevicePolicy
{
    my $self = shift;
    if (defined($$self{'device_policy'}->{'conf'})) {
        return $$self{'device_policy'}->{'conf'};
    } elsif (defined($$self{'device_policy'}->{'default'})) {
        return $$self{'device_policy'}->{'default'};
    }
    return $$self{'device_policy'}->{'static'};
}

sub getDevices
{
    my $self = shift;
    if (defined($$self{'devices'}->{'conf'})) {
        return $$self{'devices'}->{'conf'};
    } elsif (defined($$self{'devices'}->{'default'})) {
        return $$self{'devices'}->{'default'};
    }
    return $$self{'devices'}->{'static'};
}

sub setDevicePolicy
{
    my ($self, $dev_policy) = @_;
    $$self{'device_policy'}->{'conf'} = $dev_policy;
}

sub setDevices
{
    my ($self, $devices) = @_;
    $$self{'devices'}->{'conf'} = $devices;
}

1;
