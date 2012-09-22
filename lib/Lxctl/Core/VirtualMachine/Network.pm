package Lxctl::Core::VirtualMachine::Network;

use strict;
use Lxctl::Core::VirtualMachine::Network::Interface;

## Constructor
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    $$self{'ifaces'} = {};
    return bless $self;
}

