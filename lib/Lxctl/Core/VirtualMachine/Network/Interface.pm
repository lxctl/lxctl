package Lxctl::Core::VirtualMachine::Network::Interface;

use strict;

use Digest::SHA qw(sha1_hex);

## Disclaimer: do not use POD syntax for comments for now. It will make code less readable at this stage of development.

## Constructor
sub new
{
    my ($this, $conf, $defaults, $hostname) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    # 'static' is hardcoded superdefauld value
    my $self = {
        'type'   => { 'conf' => $$conf{'type'},   'default' => $$defaults{'type'},   'static' => 'veth' },
        'flags'  => { 'conf' => $$conf{'flags'},  'default' => $$defaults{'flags'},  'static' => 'up' },
        'bridge' => { 'conf' => $$conf{'bridge'}, 'default' => $$defaults{'bridge'}, 'static' => 'br0' },
        'name'   => { 'conf' => $$conf{'name'},   'default' => $$defaults{'name'},   'static' => 'eth0' },
        'mtu'    => { 'conf' => $$conf{'mtu'},    'default' => $$defaults{'mtu'},    'static' => 1500 },
        'mac'    => { 'conf' => $$conf{'mac'},    'default' => $$defaults{'mac'},    'static' => generateMAC($hostname) }
    };

    bless $self, $class;
    return $self;
}

## Checks if specified for interface bridge exists.
## TODO: check if this interface actually bridge.
sub bridgeExists
{
    my $self = shift;

    my $bridge = $self->getBridge();
    return (-e "/sys/class/net/$bridge" ? 1 : 0);
}

## Gets bridge's MTU
sub getBridgeMTU
{
    my $self = shift;

    my $bridge = $self->getBridge();
    my $mtu_path = "/sys/class/net/$bridge/mtu";
    open(my $br_mtu, "<$mtu_path")
        or die "Failed to open $mtu_path for reading\n";
    my $mtu = <$br_mtu>;
    chomp $mtu;
    return int($mtu);
}

## Return hash of interface parameters
## Had a problem: if some of parameters were got from defaults, they will be dumped too.
## But this is generally bad, because all default parameters should stay default and change when defaults change.
## May be a some sort of default-flag will help us.
sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = {'type' => $$self{'type'}->{'conf'}, 'flags' => $$self{'flags'}->{'conf'}, 'bridge' => $$self{'bridge'}->{'conf'},
                'name' => $$self{'name'}->{'conf'}, 'mtu' => $$self{'mtu'}->{'conf'}, 'mac' => $$self{'mac'}->{'conf'}};
    return $dump;
}

## Validates parameters. And add nesessary parameters to config.
sub commit
{
    my $self = shift;

    # type: veth, macvlan or dummy
    $$self{'type'}->{'conf'} = $self->getType(); # This hack adds value to vm config even if it is missed there.
    my $type = $$self{'type'}->{'conf'};
    $type eq 'veth' or $type = 'macvlan' or $type = 'dummy'
        or die "Interface type should be 'veth', 'macvlan' or 'dummy'\n";

    # flags: 
    # TODO: validate flags.
    $$self{'flags'}->{'conf'} = $self->getFlags();

    # bridge: should exist in system and must be not more then 15 characters long
    $$self{'bridge'}->{'conf'} = $self->getBridge();
    my $bridge = $$self{'bridge'}->{'conf'};
    $self->bridgeExists()
        or die "There is no bridge $bridge in the system\n";
    length($bridge) <= 15
        or die "Bridge name should be 15 characters or less\n";

    # name: should be not more then 15 characters long
    $$self{'name'}->{'conf'} = $self->getName();
    my $name = $$self{'name'}->{'conf'};
    $name =~ /^[a-zA-Z0-9]+$/
        or die "Name should contain only letters and digits\n";
    length($name) <= 15
        or die "Name should be 15 characters or less\n";

    # MTU: should be in range [1, 9000] and not be different with bridge's MTU
    my $mtu = $self->getMTU();
    if ($self->getType() eq 'veth') {
        print "> Interface " . $self->getName() . " has type 'veth'. Setting MTU to bridge's one.\n";
        $mtu = $self->getBridgeMTU();
    }
    $$self{'mtu'}->{'conf'} = $mtu;
    $mtu > 0 and $mtu < 9000
        or die "MTU should be in range [1, 9000]\n";

    # MAC: you know what it should look like
    $$self{'mac'}->{'conf'} = $self->getMAC();
    my $mac = $$self{'mac'}->{'conf'};
    $mac =~ /[a-f0-9][26ae]:([a-f0-9]{2}:){4}[a-f0-9]{2}/i
        or die "'$mac' is not valid unicast MAC address\n";
}

## TODO: Move to some helper
sub generateMAC
{
    my ($salt) = @_;
    if ((!defined($salt)) or $salt eq '') {
        $salt = int(rand(1024*1024));
        $salt = "$salt";
    }

    my $mac = sha1_hex($salt);
    $mac =~ m/(..)(..)(..)(..)(..)/;
    return "7e:$1:$2:$3:$4:$5";
}

## Getters. Returns value from vm config (if possible), otherwise value from default config (if possible), 
## otherwise hardcoded superdefault.
sub getType
{
    my $self = shift;
    if (defined($$self{'type'}->{'conf'})) {
        return $$self{'type'}->{'conf'};
    } elsif (defined($$self{'type'}->{'default'})) {
        return $$self{'type'}->{'default'};
    }
    return $$self{'type'}->{'static'};
}

sub getFlags
{
    my $self = shift;
    if (defined($$self{'flags'}->{'conf'})) {
        return $$self{'flags'}->{'conf'};
    } elsif (defined($$self{'flags'}->{'default'})) {
        return $$self{'flags'}->{'default'};
    }
    return $$self{'flags'}->{'static'};
}

sub getBridge
{
    my $self = shift;
    if (defined($$self{'bridge'}->{'conf'})) {
        return $$self{'bridge'}->{'conf'};
    } elsif (defined($$self{'bridge'}->{'default'})) {
        return $$self{'bridge'}->{'default'};
    }
    return $$self{'bridge'}->{'static'};
}

sub getName
{
    my $self = shift;
    if (defined($$self{'name'}->{'conf'})) {
        return $$self{'name'}->{'conf'};
    } elsif (defined($$self{'name'}->{'default'})) {
        return $$self{'name'}->{'default'};
    }
    return $$self{'name'}->{'static'};
}

sub getMTU
{
    my $self = shift;
    if (defined($$self{'mtu'}->{'conf'})) {
        return $$self{'mtu'}->{'conf'};
    } elsif (defined($$self{'mtu'}->{'default'})) {
        return $$self{'mtu'}->{'default'};
    }
    return $$self{'mtu'}->{'static'};
}

sub getMAC
{
    my $self = shift;
    if (defined($$self{'mac'}->{'conf'})) {
        return $$self{'mac'}->{'conf'};
    } elsif (defined($$self{'mac'}->{'default'})) {
        return $$self{'mac'}->{'default'};
    }
    return $$self{'mac'}->{'static'};
}

## Just setters. No rocket science.
sub setType
{
    my ($self, $type) = @_;
    $$self{'type'}->{'conf'} = $type;
}

sub setFlags
{
    my ($self, $flags) = @_;
    $$self{'flags'}->{'conf'} = $flags;
}

sub setBridge
{
    my ($self, $bridge) = @_;
    $$self{'bridge'}->{'conf'} = $bridge;
}

sub setName
{
    my ($self, $name) = @_;
    $$self{'name'}->{'conf'} = $name;
}

sub setMTU
{
    my ($self, $mtu) = @_;
    $$self{'mtu'}->{'conf'} = $mtu;
}

sub setMAC
{
    my ($self, $mac) = @_;
    $$self{'mac'}->{'conf'} = $mac;
}

1;
