package Lxctl::Core::VirtualMachine::Network;

use strict;
use Lxctl::Core::VirtualMachine::Network::Interface;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $hostname) = @_;
    my $class = ref($this) || $this;

    my $self = {
       'mac_generation' => { 'conf' => $$conf{'mac_generation'}, 'default' => $$defaults{'mac_generation'}, 'static' => 'random' },
    };
    $$self{'defaults'} = $defaults;
    $$self{'interfaces'} = ();
    $$self{'hostname'} = $hostname;
    $$self{'hostname'} = '' if getMacGeneration($self) ne 'hostbased';
    # TODO: this iface addition duplicates $self->addInterface().
    for my $iface (@{$$conf{'interfaces'}}) {
        push @{$$self{'interfaces'}}, new Lxctl::Core::VirtualMachine::Network::Interface($iface, $defaults, $hostname);
    }
    bless $self, $class;
    return $self;
}

sub commit
{
    my $self = shift;

    # mac_generation: should be 'random' or 'hostbased'
    my $mac_generation = $self->getMacGeneration();
    $mac_generation eq 'random' or $mac_generation eq 'hostbased'
        or die "mac_generation parameter shoud be 'random' or 'hostbased'\n";

    # commit interfaces
    for my $iface (@{$self->getInterfaces()}) {
        $iface->commit();
    }
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = {'mac_generation' => $self->getMacGeneration(), 'interfaces' => ()};
    for my $iface (@{$self->getInterfaces()}) {
        push @{$$dump{'interfaces'}, $iface->dumpConfig()};
    }

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";
    for my $iface (@{$self->getInterfaces()}) {
        $conf .= "lxc.network.type = " . $iface->getType() . "\n";
        $conf .= "lxc.network.flags = " . $iface->getFlags() . "\n";
        $conf .= "lxc.network.link = " . $iface->getBridge() . "\n";
        $conf .= "lxc.network.name = " . $iface->getName() . "\n";
        $conf .= "lxc.network.mtu = " . $iface->getMTU() . "\n";
        $conf .= "lxc.network.hwaddr = " . $iface->getMAC() . "\n";
        $conf .= "\n";
    }

    return $conf;
}

sub addInterface
{
    my ($self, $type, $flags, $bridge, $name, $mtu, $mac) = @_;

    for my $iface (@{$self->getInterfaces()}) {
        my $iface_name = $iface->getName();
        defined($name) and $iface_name ne $name
            or die "Duplicate interface names '$name'\n";
        defined($mac) and $iface->getMAC() ne $mac
            or die "Duplicate MAC addresses on interfaces '$iface_name' add '$name'\n";
    }
    my $conf = {'type' => $type, 'flags' => $flags, 'bridge' => $bridge, 'name' => $name,
                'mtu' => $mtu, 'mac' => $mac};
    push @{$self->getInterfaces()}, new Lxctl::Core::VirtualMachine::Network::Interface($conf, $self->getDefaults(), $self->getHostname());
}

sub deleteInterface
{
    my ($self, $name) = @_;

    my @new_interfaces;
    my $found = 0;
    for my $iface (@{$self->getInterfaces()}) {
        if ($iface->getName() ne $name) {
            push @new_interfaces, $iface;
        } else {
            $found = 1;
        }
    }

    $found or die "There is no interface named '$name'\n";

    $self->setInterfaces(\@new_interfaces);
}

sub getHostname
{
    my $self = shift;
    return $$self{'hostname'};
}

sub getInterfaces
{
    my $self = shift;
    return $$self{'interfaces'};
}

sub getDefaults
{
    my $self = shift;
    return $$self{'defaults'};
}

sub getMacGeneration
{
    my $self = shift;

    if (defined($$self{'mac_generation'}->{'conf'})) {
        return $$self{'mac_generation'}->{'conf'};
    } elsif (defined($$self{'mac_generation'}->{'default'})) {
        return $$self{'mac_generation'}->{'default'};
    }
    return $$self{'mac_generation'}->{'static'};
}

sub setInterfaces
{
    my ($self, $ifaces) = @_;
    $$self{'interfaces'} = $ifaces;
}

1;
