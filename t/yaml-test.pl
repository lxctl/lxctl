#!/usr/bin/perl
use strict;
use warnings;
use Lxc::object;
use YAML::Tiny;

my $yaml = YAML::Tiny->new;

$yaml->[0]->{paths} = {LXC_CONF_DIR => '/var/lib/lxc',
		ROOTS_PATH => '/var/lxc/root',
		CONFIG_PATH => '/var/lib/lxc',
		TEMPLATE_PATH => '/var/lxc/templates',
};

$yaml->[0]->{lvm} = {VG => 'vg0', };

$yaml->write('config.yaml');

$yaml = YAML::Tiny->read('config2.yaml');
my $lxc = new Lxc::object;

$lxc->set_lxc_conf_dir($yaml->[0]->{paths}->{LXC_CONF_DIR});
$lxc->set_roots_path($yaml->[0]->{paths}->{ROOTS_PATH});
$lxc->set_config_path($yaml->[0]->{paths}->{CONFIG_PATH});
$lxc->set_template_path($yaml->[0]->{paths}->{TEMPLATE_PATH});
$lxc->set_vg($yaml->[0]->{lvm}->{VG});

my $tmp = $lxc->get_lxc_conf_dir();
print "LXC_CONF_DIR is $tmp\n";

$tmp = $lxc->get_roots_path();
print "LXC_CONF_DIR is $tmp\n";

$tmp = $lxc->get_config_path();
print "CONFIG_PATH is $tmp\n";

$tmp = $lxc->get_template_path();
print "TEMPLATE_PATH is $tmp\n";

$tmp = $lxc->get_vg();
print "VG is $tmp\n";
