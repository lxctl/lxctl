package Lxctl::Core::VirtualMachine::CGroups::Memory;

use strict;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $cgroup_path, $cgroup_name, $online_change) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    my $self = {
        'mem_soft_limit' => { 'conf' => $$conf{'mem_soft_limit'}, 'default' => $$defaults{'mem_soft_limit'} },
        'mem_limit' =>      { 'conf' => $$conf{'mem_limit'},      'default' => $$defaults{'mem_limit'} },
        'mem_swap_limit' => { 'conf' => $$conf{'mem_swap_limit'}, 'default' => $$defaults{'mem_swap_limit'} },
        'mem_swappiness' => { 'conf' => $$conf{'mem_swappiness'}, 'default' => $$defaults{'mem_swappiness'} },
    };
    $$self{'cgroup_path'} = $cgroup_path;
    $$self{'cgroup_name'} = $cgroup_name;
    $$self{'online_change'} = $online_change;

    bless $self, $class;
    return $self;
}

sub commit
{
    my $self = shift;

    # mem_soft_limit: should be > 0
    my $mem_soft_limit = $self->getMemSoftLimit();
    $mem_soft_limit > 0
        or die "mem_soft_limit should be positive integer";

    # mem_limit: should be > 0
    my $mem_limit = $self->getMemLimit();
    $mem_limit > 0
        or die "mem_limit should be positive integer";

    # mem_swap_limit: should be > 0
    my $mem_swap_limit = $self->getMemSwapLimit();
    $mem_swap_limit > 0
        or die "mem_swap_limit should be positive integer";

    # mem_swappiness: should be > 0
    my $mem_swappiness = $self->getMemSwapiness();
    $mem_swappiness > 0
        or die "mem_swappiness should be positive integer";
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = { 'mem_soft_limit' => $$self{'mem_soft_limit'}->{'conf'}, 'mem_limit' => $$self{'mem_limit'}->{'conf'}, 
                 'mem_swap_limit' => $$self{'mem_swap_limit'}->{'conf'}, 'mem_swappiness' => $$self{'mem_swappiness'}->{'conf'} };

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";
    my $mem_soft_limit = $self->getMemSoftLimit();
    if (defined($mem_soft_limit) and $mem_soft_limit ne '') {
        $conf .= "lxc.cgroup.memory.soft_limit_in_bytes = $mem_soft_limit\n";
    }
    my $mem_limit = $self->getMemLimit();
    if (defined($mem_limit) and $mem_limit ne '') {
        $conf .= "lxc.cgroup.memory.limit_in_bytes = $mem_limit\n";
    }
    my $mem_swap_limit = $self->getMemSwapLimit();
    if (defined($mem_swap_limit) and $mem_swap_limit ne '') {
        $conf .= "lxc.cgroup.memory.memsw.limit_in_bytes = $mem_swap_limit\n";
    }
    my $mem_swappiness = $self->getMemSwappiness();
    if (defined($mem_swappiness) and $mem_swappiness ne '') {
        $conf .= "lxc.cgroup.memory.memsw.limit_in_bytes = $mem_swappiness\n";
    }

    return $conf;
}

sub writeToFile
{
    my ($self, $file, $value) = @_;

    return if ($$self{'online_change'} != 0);

    my $file = "$$self{'cgroup_path'}/$$self{'cgroup_name'}/$file";
    open my $cgrp_file, ">$file"
        or die "Failed to open $file for writing\n";
    print $cgrp_file $value . "\n";
    close $cgrp_file;
}

sub getMemLimit
{
    my $self = shift;
    
    if (defined($$self{'mem_limit'}->{'conf'})) {
        return $$self{'mem_limit'}->{'conf'};
    } elsif (defined($$self{'mem_limit'}->{'default'})) {
        return $$self{'mem_limit'}->{'default'};
    }
    return;
}

sub getMemSoftLimit
{
    my $self = shift;
    
    if (defined($$self{'mem_soft_limit'}->{'conf'})) {
        return $$self{'mem_soft_limit'}->{'conf'};
    } elsif (defined($$self{'mem_soft_limit'}->{'default'})) {
        return $$self{'mem_soft_limit'}->{'default'};
    }
    return;
}

sub getMemSwapLimit
{
    my $self = shift;
    
    if (defined($$self{'mem_swap_limit'}->{'conf'})) {
        return $$self{'mem_swap_limit'}->{'conf'};
    } elsif (defined($$self{'mem_swap_limit'}->{'default'})) {
        return $$self{'mem_swap_limit'}->{'default'};
    }
    return;
}

sub getMemSwappiness
{
    my $self = shift;
    
    if (defined($$self{'mem_swappiness'}->{'conf'})) {
        return $$self{'mem_swappiness'}->{'conf'};
    } elsif (defined($$self{'mem_swappiness'}->{'default'})) {
        return $$self{'mem_swappiness'}->{'default'};
    }
    return;
}

sub setMemLimit
{
    my ($self, $value) = @_;
    $$self{'mem_limit'}->{'conf'} = $value;
    $self->writeToFile('memory.limit_in_bytes', $value);
}

sub setMemSoftLimit
{
    my ($self, $value) = @_;
    $$self{'mem_soft_limit'}->{'conf'} = $value;
    $self->writeToFile('memory.soft_limit_in_bytes', $value);
}

sub setMemSwapLimit
{
    my ($self, $value) = @_;
    $$self{'mem_swap_limit'}->{'conf'} = $value;
    $self->writeToFile('memory.memsw.limit_in_bytes', $value);
}

sub setMemSwappiness
{
    my ($self, $value) = @_;
    $$self{'mem_swappiness'}->{'conf'} = $value;
    $self->writeToFile('memory.swappiness', $value);
}

1;
