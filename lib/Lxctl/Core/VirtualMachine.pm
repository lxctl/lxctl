package Lxctl::Core::VirtualMachine;

use strict;

use Lxctl::Core::VirtualMachine::Network;

## Constructor
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    $$self{'Network'} = Lxctl::Core::VirtualMachine::Network->new();
    return bless $self;
}


