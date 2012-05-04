#!/usr/bin/perl

use warnings;
use strict;

use Lxctl::Helpers::config;
use Lxctl::Helpers::optionsValidator;
use Lxctl::Helpers::lxcConfGenerator;
use Lxctl::set;

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
		'type' => ['enum', 'veth', ['macvlan','veth']], # TODO: add all other types
		'flags' => ['str', 'up'],
		'bridge' => ['str', 'br0'],
		'name' => ['str', 'eth0'],
		'mtu' => ['int', '1500'],
		'mac' => ['mac', sub{$setter->mac_create($hash{'contname'})}],
	},
	'ttys' => ['int', 4],
	'pts' => ['int', 1024],
);
$validator->act(undef, \%hash, \%extra);
print STDERR "Generating...\n";
$confGenerator->convert(\%hash);

