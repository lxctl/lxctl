package Lxctl::Core::VirtualMachine::CGroups::CPU;

use strict;

## Constructor
sub new
{
    my ($this, $conf, $defaults, $cgroup_path, $cgroup_name, $online_change) = @_;
    my $class = ref($this) || $this;

    # 'conf' is for value from vm config
    # 'default' if for value from defaults config
    my $self = {
        'cpus' => { 'conf' => $$conf{'cpus'}, 'default' => $$defaults{'cpus'} },
        'cpus_exclusive' =>      { 'conf' => $$conf{'cpus_exclusive'},      'default' => $$defaults{'cpus_exclusive'} },
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

    # cpus: should be something like '0,5-8,11-13'
    my $cpus = $self->getCPUs();
    $cpus =~ /([0-9]+(-[0-9]+)?,)*[0-9]+(-[0-9]+)?/
        or die "'cpus' parameter should be a list of processor numbers or processor number ranges\n";

    # cpus_exclusive: should be 0 or 1
    my $cpus_ex = $self->getCPUsExclusive();
    $cpus_ex == 0 or $cpus_ex == 1
        or die "cpus_exclusive should be 0 or 1\n";
}

sub dumpConfig
{
    my $self = shift;

    $self->commit();

    my $dump = { 'cpus' => $$self{'cpus'}->{'conf'}, 'cpus_exclusive' => $$self{'cpus_exclusive'}->{'conf'} };

    return $dump;
}

sub generateLxcConfig
{
    my $self = shift;

    $self->commit();

    my $conf = "";
    my $cpus = $self->getCPUs();
    if (defined($cpus) and $cpus ne '') {
        $conf .= "lxc.cgroup.cpuset.cpus = $cpus\n";
    }
    my $cpus_ex = $self->getCPUsExclusive();
    if (defined($cpus_ex) and $cpus_ex ne '') {
        $conf .= "lxc.cgroup.cpuset.cpu_exclusive = $cpus_ex\n";
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

sub getCPUs
{
    my $self = shift;
    
    if (defined($$self{'cpus'}->{'conf'})) {
        return $$self{'cpus'}->{'conf'};
    } elsif (defined($$self{'cpus'}->{'default'})) {
        return $$self{'cpus'}->{'default'};
    }
    return;
}

sub getCPUsExclusive
{
    my $self = shift;
    
    if (defined($$self{'cpus_exclusive'}->{'conf'})) {
        return $$self{'cpus_exclusive'}->{'conf'};
    } elsif (defined($$self{'cpus_exclusive'}->{'default'})) {
        return $$self{'cpus_exclusive'}->{'default'};
    }
    return;
}

sub setCPUs
{
    my ($self, $value) = @_;
    $$self{'cpus'}->{'conf'} = $value;
    $self->writeToFile('cpuset.cpus', $value);
}

sub setCPUsExclusive
{
    my ($self, $value) = @_;
    $$self{'cpus_exclusive'}->{'conf'} = $value;
    $self->writeToFile('cpuset.cpu_exclusive', $value);
}

1;
