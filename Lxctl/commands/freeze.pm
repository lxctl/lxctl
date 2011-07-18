package Lxctl::commands::freeze;

use strict;
use warnings;

use Lxc::object;

my %options = ();

sub do
{
	my $self = shift;

	$options{'contname'} = shift
		or die "Name the container please!\n\n";

	eval {
		$self->{'lxc'}->freeze($options{'contname'});
	} or do {
		print "$@";
		die "Cannot freeze $options{'contname'}!\n\n";
	};

	print "Successfuly frozen!\n";
	return;
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = new Lxc::object;

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
