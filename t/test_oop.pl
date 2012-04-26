#!/usr/bin/perl
use Lxc::object;
use Test::More tests => 6;

my $lxc = new Lxc::object;

my $tmp = $lxc->check();

my $tmp2 = $lxc->get_vg();

$lxc->set_vg("TEMP!");

$tmp = $lxc->get_vg();

$lxc->set_vg($tmp2);

eval {
	$tmp = $lxc->get_conf("testvm", "lxc.rootfs");
} or do {
	print "Can't run, testvm is not avaliable\n";
};

ok(defined($lxc->get_config_path()), "Should be defined");
ok(defined($lxc->get_roots_path()), "Should be defined");
ok(defined($lxc->get_template_path()), "Should be defined");
ok(defined($lxc->get_lxc_conf_dir()), "Should be defined");
ok(defined($lxc->get_cgroup_path()), "Should be defined");
ok(defined($lxc->get_vg()), "Should be defined");

$tmp = $lxc->get_config_path();
print "CONFIG_PATH: $tmp\n";

$tmp = $lxc->get_roots_path();
print "ROOTS_PATH: $tmp\n";

$tmp = $lxc->get_template_path();
print "TEMPLATE_PATH: $tmp\n";

$tmp = $lxc->get_lxc_conf_dir();
print "LXC_CONF_DIR: $tmp\n";

$tmp = $lxc->get_cgroup_path();
print "CGROUP_PATH: $tmp\n";

$tmp = $lxc->get_vg();
print "VG: $tmp\n";

