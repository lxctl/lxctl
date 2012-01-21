#!/usr/bin/perl

use strict;
use YAML::Tiny qw(LoadFile);
use Lxctl::Helpers::configValidator;

my $yaml = YAML::Tiny->read($ARGV[0]);

my $validator = new Lxctl::Helpers::configValidator;

my %yaml_n = $validator->validate($yaml->[0]);

for my $k (keys %yaml_n) {
	print "$k:\n";
	for my $k2 (keys %{$yaml_n{$k}}) {
		print "    $k2: $yaml_n{$k}->{$k2}\n";
	}
}
