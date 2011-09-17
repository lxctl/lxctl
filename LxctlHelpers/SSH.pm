package LxctlHelpers::SSH

use strict;
use Net::SSH2;

my $ssh_ = Net::SSH2->new();

sub connect {
    my ($server, $user, $port) = @_;
    $ssh_->connect($server);
    $ssh_->auth_publickey($user, '/root/.ssh/id_rsa.pub', '/root/.ssh/id_rsa');
    $ssh_->auth_ok() or die "Failed to authenticate at $user\@$server with public key.\n\n";
}

sub exec {
    my $cmd = shift;
    my $ssh_ch = $ssh->channel();
    $ssh_ch->exec($cmd);
}

sub get_file {
    my ($from, $to) = @_;
    my $sftp = $ssh_->sftp();
    my $r_file = $sftp->open($from, O_RDONLY)
        or die "Failed to open remote file $from.\n\n";
    my $l_file = open($to, O_WRONLY|O_CREAT|O_TRUNC, 0600)
        or die "Failed to open local file $to.\n\n";

    print $l_file $_ while <$r_file>;
}

sub put_file {
    my ($from, $to) = @_;
    my $sftp = $ssh_->sftp();
    my $r_file = $sftp->open($to, O_RDONLY)
        or die "Failed to open remote file $to.\n\n";
    my $l_file = open($from, O_WRONLY|O_CREAT|O_TRUNC, 0600)
        or die "Failed to open local file $from.\n\n";

    print $r_file $_ while <$l_file>;
}

1;
