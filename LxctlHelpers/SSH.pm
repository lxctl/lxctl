package LxctlHelpers::SSH;

use strict;
use warnings;
use Net::SSH2;
use Fcntl;

my $ssh_ = Net::SSH2->new();

sub connect {
    my ($self, $server, $user, $port) = @_;
    $ssh_->connect($server);
    $ssh_->auth_publickey($user, '/root/.ssh/id_rsa.pub', '/root/.ssh/id_rsa');
    $ssh_->auth_ok() or die "Failed to authenticate at $user\@$server with public key.\n\n";

    return $self;
}

sub execute {
    my ($self, $cmd) = @_;
    my $ssh_ch = $ssh_->channel();
    $ssh_ch->exec($cmd);
}

sub get_file {
    my ($self, $from, $to) = @_;

    print "Copying local $from to remote $to...\n";

    return $ssh_->scp_put($from, $to);
}

sub put_file {
    my ($self, $from, $to) = @_;

    print "Copying local $from to remote $to...\n";

    return $ssh_->scp_put($from, $to);
}

1;
