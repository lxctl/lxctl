#!/usr/bin/perl

use strict;

use Lxctl::Core::VirtualMachine::Devices;

my $defaultsConf = {};
print "Using defaults:\n";
for my $i (keys %$defaultsConf) {
    print "  $i: $$defaultsConf{$i}\n";
}

my $correctConf = {};
print "\nUsing config:\n";
for my $i (keys %$correctConf) {
    print "  $i: $$correctConf{$i}\n";
}

print "\nStart test...\n";

my $Dev = new Lxctl::Core::VirtualMachine::Devices($correctConf, $defaultsConf);

my $conf = $Dev->generateLxcConfig();

print "\nGot LXC config:\n";
print $conf;

