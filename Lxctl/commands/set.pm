package Lxctl::commands::set;

use strict;
use warnings;

use Getopt::Long;

use Lxc::object;

use Lxctl::helpers::_config;
use Lxctl::helpers::_plugins search_path => ['Lxctl::plugins::set'], instantiate => "new";

my %options = ();

our $AUTOLOAD;

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	$Getopt::Long::passthrough = 1;
	GetOptions(\%options, 'ipadd|ipaddr=s', 'hostname=s', 'userpasswd=s', 
		'nameserver=s', 'searchdomain=s', 'rootsz=s', 
		'netmask|mask=s', 'defgw|gw=s', 'dns=s', 'cpus=s', 'cpu-shares=s', 'mem=s', 'io=s', 
		'macaddr=s', 'autostart=s', 'tz=s', 'debug!');
	$Getopt::Long::passthrough = 0;

	# Maybe it's a bit magical, but I can't make getopt to parse all options.
	# Should be used by plugins to parse unknown options.
	foreach my $cmd (@ARGV) {
		my ($call) = $cmd =~ m/--([^=]*)/;
		if (defined($call)) {
			print "DEBUG: $cmd\n";
			print "CALL: \"$call\"\n";
			$self->$call;
		}
		#$self->$call;
	}

	if (defined($options{'mem'})) {
		$options{'mem'} = $self->{'lxc'}->convert_size($options{'mem'}, "B");
	}

	# Dirty hack. set_macaddr used from create and should be able to work without --macaddr option.
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
	my @result;

	my $config = new Lxctl::helpers::_config;
	my $blacklist_ref = $config->load_plugin_blacklist();
	my %blacklist = %$blacklist_ref;

	$result[0] = 0;
	$result[1] = "";
	if ($function eq "DESTROY") {
		return;
	}

	for my $plugin ($self->plugins_ordered(\%options)) {
		my ($plugin_name) = $plugin =~ m/plugins::set::(.*)=.*/;
		next if (defined($blacklist{$plugin_name}));

		eval {
			@result = $plugin->$function(@_);
		};

		if ($options{'debug'}) {
			print "Called $plugin->$function\n";
		}

		if ($result[1] ne "") {
			print "$result[1]";
		}

		if ($result[0] eq "1") {
			return;
		}

		if ($result[0] eq "2") {
			die "Fatal error";
		}
	}
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
