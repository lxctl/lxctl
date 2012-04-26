#!/usr/bin/perl

use strict;
use warnings;
use Lxc;
use Test::More tests => 10;
use Test::Trap;

our @list;

# Checking container
#checking path
ok(defined(Lxc::get_config_path()), "LXC_CONF_DIR is defined");
Lxc::set_config_path("/var/lib/");
ok(Lxc::get_config_path() eq "/var/lib/", "LXC_CONF_DIR can be changed");

Lxc::set_config_path("/var/lib/lxc");

@list = Lxc::ls();

ok(Lxc::status() eq "", "Testing Lxc::control::state without vmname");
my @r = trap { Lxc::Kill("abrakadabra", "SIGKILL") };
is ($trap->exit, undef, 'Expecting exit with undef');
is ($trap->stdout, '', "No STDOUT" );
is ($trap->stderr, '', "No STDERR");
print "------------------\n";

ok(Lxc::start("abrakadabra") == 1, "Lxc::start shouldn't start non-existing container");
ok(Lxc::stop("abrakadabra") == 1, "Lxc::stop can stop non-existing machine: just should do nothing");
ok(Lxc::freeze("abrakadabra") == 1, "Lxc::freeze should fail to freeze machine");
ok(Lxc::unfreeze("abrakadabra") == 1, "Lxc::freeze should fail to freeze machine");
