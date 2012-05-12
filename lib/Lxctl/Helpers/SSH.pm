package Lxctl::Helpers::SSH;

use strict;
use warnings;
use 5.010001;

my $ssh_;
my $_ssh_user;
my $_ssh_server;
my $_ssh_port;

sub connect {
	my $self = shift;
	($_ssh_server, $_ssh_user, $_ssh_port) = @_;

        return $self;
}

sub execute {
        my ($self, $cmd) = @_;
        (system("ssh -p $_ssh_port $_ssh_user\@$_ssh_server '$cmd'") == 0) or die "Failed to remotely execute '$cmd'.\n";
}

sub get_file {
        my ($self, $from, $to) = @_;

        print "Copying local $from to remote $to...\n";

        (system("scp -r -P $_ssh_port $_ssh_user\@$_ssh_server:$from $to") == 0) or die "Failed to copy.\n\n";
        return 1;
}

sub put_file {
        my ($self, $from, $to) = @_;

        print "Copying local $from to remote $to...\n";

        (system("scp -r -P $_ssh_port $from $_ssh_user\@$_ssh_server:$to") == 0) or die "Failed to copy.\n\n";
        return 1;
}

1;
__END__

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
