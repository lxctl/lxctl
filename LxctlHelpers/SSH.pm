package LxctlHelpers::SSH;

use strict;
use warnings;

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
