package Lxctl::plugins::create::ubuntu;
use base qw(Lxctl::plugins::create::base);

use strict;
use warnings;

use Getopt::Long;

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new();

	print "Lxctl::plugins::create::ubuntu initialized\n";
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
