#!/usr/bin/perl

use warnings;
use strict;

use Lxctl::Helpers::config;
use Lxctl::Helpers::optionsValidator;
use Lxctl::Helpers::lxcConfGenerator;
use Lxctl::set;
use Data::Dumper;

my $config = new Lxctl::Helpers::config;
my $confGenerator = new Lxctl::Helpers::lxcConfGenerator;
my $validator = new Lxctl::Helpers::optionsValidator;
my %options = (
	'contname' => './natty-test.yaml',
);
my $result = $config->load_file($options{'contname'});
my %hash = %{$result};
my $setter = new Lxctl::set;

print STDERR "Validating hash...\n";

my %extra = (
	'interfaces' => {
		'type' => ['enum', 'veth', ['macvlan','veth', 'vlan', 'phys']],
		'flags' => ['str', 'up'],
		'bridge' => ['str', 'br0'],
		'name' => ['str', 'eth0'],
		'extname' => [ 'str', ''],
		'mtu' => ['int', '1500'],
		'mac' => ['mac', sub{$setter->mac_create($hash{'contname'})}],
	},
	'devices' => {
		'allow' => ['array', ['c 1:3 rwm', 'c 1:5 rwm', 'c 5:1 rwm', 'c 5:0 rwm', 'c 4:0 rwm', 'c 4:1 rwm', 'c 1:9 rwm', 'c 1:8 rwm', 'c 136:* rwm', 'c 5:2 rwm', 'c 254:0 rwm']],
		'deny' => ['array', ['a']],
	},
	'ttys' => ['int', 4],
	'pts' => ['int', 1024],
);
$validator->act(\%hash, \%extra);
print STDERR "Generating...\n";
$confGenerator->convert(\%hash);

