#!/usr/bin/perl

use strict;

use Lxctl::Core::VirtualMachine::Network;

my $defaultsConf = { 'type' => 'veth', 'bridge' => 'eth0', 'flags' => 'up', 'name' => 'eth0' };
print "Using defaults:\n";
for my $i (keys %$defaultsConf) {
    print "  $i: $$defaultsConf{$i}\n";
}

my $correctConf = { 'mac_generation' => 'hostbased', 'interfaces' => [ {'mtu' => 9000, 'name' => 'eth0'}, {'name' => 'eth1'} ] };
print "\nUsing config:\n";
for my $i (keys %$correctConf) {
    if ($i eq 'interfaces') {
        print "  $i:\n";
        for my $iface (@{$$correctConf{'interfaces'}}) {
            print "    -\n";
            for my $j (keys %$iface) {
                print "    $j: $$iface{$j}\n";
            }
        }
    } else {
        print "  $i: $$correctConf{$i}\n";
    }
}

print "\nStart test...\n";

my $Ntwrk = new Lxctl::Core::VirtualMachine::Network($correctConf, $defaultsConf, "blah");

my $conf = $Ntwrk->generateLxcConfig();

print "\nGot LXC config:\n";
print $conf;

#print "\nGot config:\n";
#for my $i (keys %$conf) {
#    print "  $i: $$conf{$i}\n";
#}

