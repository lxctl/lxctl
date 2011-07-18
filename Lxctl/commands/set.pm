package Lxctl::commands::set;

use strict;
use warnings;

use Getopt::Long;
use Module::Pluggable::Ordered search_path => ['Lxctl::plugins::set'];

use Lxc::object;

use Lxctl::helpers::_config;

my %options = ();

our $AUTOLOAD;

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	GetOptions(\%options, 'ipadd|ipaddr=s', 'hostname=s', 'userpasswd=s', 
		'nameserver=s', 'searchdomain=s', 'rootsz=s', 
		'netmask|mask=s', 'defgw|gw=s', 'dns=s', 'cpus=s', 'cpu-shares=s', 'mem=s', 'io=s', 
		'macaddr=s', 'autostart=s', 'tz=s');

	if (defined($options{'mem'})) {
		$options{'mem'} = $self->{'lxc'}->convert_size($options{'mem'}, "B");
	}

	# Dirty hack. set_macaddr used from create and should be able to work without --maccaddr option.
	$self->set_macaddr() if defined($options{'macaddr'});
	$self->set_ipadd();
	$self->set_netmask();
	$self->set_defgw();
	$self->set_dns();
	$self->set_hostname();
	$self->set_searchdomain();
	$self->set_userpasswd();
	$self->set_rootsz();
	$self->set_autostart();
	$self->set_tz();
	$self->set_cgroup('cpu-shares', 'cpu.shares');
	$self->set_cgroup('cpus', 'cpuset.cpus');
	$self->set_cgroup('mem', 'memory.limit_in_bytes');
	$self->set_cgroup('io', 'blkio.weight');

	my $config = new Lxctl::helpers::_config;
	$config->change_hash(\%options, "$self->{'CONFIG_PATH'}/$options{'contname'}.yaml");

	return;
}

sub AUTOLOAD
{
	my $self = shift;
	my ($function) = $AUTOLOAD =~ m/.*::(.*)$/;
	if ($function eq "DESTROY") {
		return;
	}
#	my @plugins;
#	print "Function $function not found, trying to find in plugins...\n";
	for my $plugin ($self->plugins_ordered(%options)) {
		eval {
			$plugin->$function(@_);
			print "Called $plugin $function\n";
		}
	}

#	print "Found:";
#	foreach my $val (@plugins) {
#		print " $val";
#	}
#	print "\n";

#	my %call_stack;
#	for my $plugin ($self->plugins(%options)) {
#		my $order = 50;
#		eval {
#			$order = $plugin->_order;
#		};
#		$call_stack{$order} .= '%%' . $plugin;
#	}
#	foreach my $plugin_order (sort keys %call_stack) {
#		my @plugin_list = split(/%%/, $call_stack{$plugin_order});
#		foreach my $plugin (@plugin_list) {
#			next if (!defined $plugin || $plugin eq "");
#			eval {
#				print "Called: $plugin $function\n";
#
#				$plugin->$function(@_);
#			} or do {
#				print "Failed with $@\n";
#			}
#		}
#	}
}

sub new
{
	my $class = shift;	
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = Lxc::object->new;
	$self->{'helper'} = new Lxctl::helpers::_general;

	$self->{'CONFIG_PATH'} = $self->{'lxc'}->get_config_path();

	%options = @_;

	return $self;
}

1;
__END__
=head1 NAME

Lxctl::destroy

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

Man page by Capitan Obvious.

=head2 EXPORT

None by default.

=head2 Exportable constants

None by default.

=head2 Exportable functions

TODO

=head1 AUTHOR

Anatoly Burtsev, E<lt>anatolyburtsev@yandex.ruE<gt>
Pavel Potapenkov, E<lt>ppotapenkov@gmail.comE<gt>
Vladimir Smirnov, E<lt>civil.over@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Anatoly Burtsev, Pavel Potapenkov, Vladimir Smirnov

This library is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

=cut
