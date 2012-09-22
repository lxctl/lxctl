#!/usr/bin/perl

use strict;

use Lxctl::Core::VirtualMachine::Network::Interface;

my $defaultsConf = { 'type' => 'veth', 'bridge' => 'eth0', 'flags' => 'up', 'name' => 'eth0' };
print "Using defaults:\n";
for my $i (keys %$defaultsConf) {
    print "  $i: $$defaultsConf{$i}\n";
}

my $correctConf = { 'mtu' => 9000 };
print "\nUsing config:\n";
for my $i (keys %$correctConf) {
    print "  $i: $$correctConf{$i}\n";
}

print "\nStart test...\n";

my $Iface = new Lxctl::Core::VirtualMachine::Network::Interface($correctConf, $defaultsConf);

my $conf = $Iface->dumpConfig();

print "\nGot config:\n";
for my $i (keys %$conf) {
    print "  $i: $$conf{$i}\n";
}

