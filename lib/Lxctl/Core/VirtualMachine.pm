package Lxctl::Core::VirtualMachine;

use strict;

use Lxctl::Core::VirtualMachine::Network;
use Lxctl::Core::VirtualMachine::Cgroups;
use Lxctl::Core::VirtualMachine::System;
use Lxctl::Core::VirtualMachine::Runtime;

## Constructor
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    $$self{'Network'} = new Lxctl::Core::VirtualMachine::Network;
    $$self{'CGroups'} = new Lxctl::Core::VirtualMachine::Cgroups;
    $$self{'System'} = new Lxctl::Core::VirtualMachine::System;
    $$self{'Runtime'} = new Lxctl::Core::VirtualMachine::Runtime;
    return bless $self, class;
}

1;
