package Lxctl::commands::create;

use strict;
use warnings;

use Getopt::Long;

use Lxctl::helpers::_general;


my $config = new Lxctl::helpers::_config;

my %options = ();

sub do
{
	my $self = shift;
	my $plugin;
	my $distroclass = "ubuntu";
	my $helper = new Lxctl::helpers::_general;

	$Getopt::Long::passthrough = 1;
	
	GetOptions('distroclass=s' => \$distroclass);
	$Getopt::Long::passthrough = 0;
	eval {
		$helper->load_module("Lxctl/plugins/create/$distroclass.pm");
		my $plugin_name = "Lxctl::plugins::create::$distroclass";
		$distroclass->import;
		$plugin = new $plugin_name;
	} or do {
		print "Falling back to base plugin: $@";
		$helper->load_module("Lxctl/plugins/create/base.pm");
		my $plugin_name = "Lxctl::plugins::create::base";
		$distroclass->import;
		$plugin = new $plugin_name;
	};

	$plugin->do(@ARGV);
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}


1;
__END__

=head1 NAME

Lxctl::create

=head1 SYNOPSIS

Basic create command. Should be sufficient for all needs

=head1 DESCRIPTION

Basic create command. Should be sufficient for all needs

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
