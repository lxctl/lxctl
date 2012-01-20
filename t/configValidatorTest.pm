#!/usr/bin/perl

use strict;
use YAML::Tiny qw(LoadFile);
use Lxctl::Helpers::configValidator;

my $yaml = YAML::Tiny->read($ARGV[0]);

my $validator = new Lxctl::Helpers::configValidator;

$validator-> validate($yaml);
