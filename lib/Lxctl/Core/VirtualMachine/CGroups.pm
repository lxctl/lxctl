package Lxctl::Core::VirtualMachine::CGroups;

use strict;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $cgroup_path, $cgroup_name) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    my $online_change = (-d "$cgroup_path/$cgroup_name" ? 1 : 0);
    my $self = {};
    $$self{'Devices'} = new Lxctl::Core::VirtualMachine::CGroups::Devices($$conf{'devices'}, $$defaults{'devices'}, $cgroup_path, $cgroup_name, $online_change);
    $$self{'Memory'} = new Lxctl::Core::VirtualMachine::CGroups::Memory($$conf{'memory'}, $$defaults{'memory'}, $cgroup_path, $cgroup_name, $online_change);
    $$self{'CPU'} = new Lxctl::Core::VirtualMachine::CGroups::CPU($$conf{'cpu'}, $$defaults{'cpu'}, $cgroup_path, $cgroup_name, $online_change);

    bless $self, $class;
    return $self;
}

sub commit
{
    my $self = shift;

    $$self{'Devices'}->commit();
    $$self{'Memory'}->commit();
    $$self{'CPU'}->commit();
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = {'devices' => $$self{'Devices'}->dumpConfig(), 'memory' => $$self{'Memory'}->dumpConfig(), 'cpu' => $$self{'CPU'}->dumpConfig() };

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";

    $conf .= $$self{'Devices'}->generateLxcConfig() . "\n";
    $conf .= $$self{'Memory'}->generateLxcConfig() . "\n";
    $conf .= $$self{'CPU'}->generateLxcConfig() . "\n";

    return $conf;
}

sub setCPUs
{
    my ($self, $value) = @_;
    $$self{'CPU'}->setCPUs($value);
}

sub setCPUsExclusive
{
    my ($self, $value) = @_;
    $$self{'CPU'}->setCPUsExclusive($value);
}

sub setMemLimit
{
    my ($self, $value) = @_;
    $$self{'Memory'}->setMemLimit($value);
}

sub setMemSoftLimit
{
    my ($self, $value) = @_;
    $$self{'Memory'}->setMemSoftLimit($value);
}

sub setMemSwapLimit
{
    my ($self, $value) = @_;
    $$self{'Memory'}->setMemSwapLimit($value);
}

sub setMemSwappiness
{
    my ($self, $value) = @_;
    $$self{'Memory'}->setMemSwappiness($value);
}

sub setDevicePolicy
{
    my ($self, $value) = @_;
    $$self{'Devices'}->setDevicePolicy($value);
}

sub setDevices
{
    my ($self, $value) = @_;
    $$self{'Devices'}->setDevices($value);
}

sub addDevice
{
    my ($self, $value) = @_;
    $$self{'Devices'}->addDevice($value);
}

sub deleteDevice
{
    my ($self, $value) = @_;
    $$self{'Devices'}->deleteDevice($value);
}

sub getCPUs
{
    my ($self) = @_;
    return $$self{'CPU'}->getCPUs();
}

sub getCPUsExclusive
{
    my ($self) = @_;
    return $$self{'CPU'}->getCPUsExclusive();
}

sub getMemLimit
{
    my ($self) = @_;
    return $$self{'Memory'}->getMemLimit();
}

sub getMemSoftLimit
{
    my ($self) = @_;
    return $$self{'Memory'}->getMemSoftLimit();
}

sub getMemSwapLimit
{
    my ($self) = @_;
    return $$self{'Memory'}->getMemSwapLimit();
}

sub getMemSwappiness
{
    my ($self) = @_;
    return $$self{'Memory'}->getMemSwappiness();
}

sub getDevicePolicy
{
    my ($self) = @_;
    return $$self{'Devices'}->getDevicePolicy();
}

sub getDevices
{
    my ($self) = @_;
    return $$self{'Devices'}->getDevices();
}

1;
