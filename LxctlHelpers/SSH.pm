package LxctlHelpers::SSH;

use strict;
use warnings;
use Net::OpenSSH;
use Fcntl;

my $ssh_;

sub connect {
	my ($self, $server, $user, $port) = @_;
	$ssh_ = Net::OpenSSH->new("$user\@$server:$port");
	$ssh_->error and die "Failed to connect to $user\@$host:$port: $ssh_->error.\n\n";

	return $self;
}

sub execute {
	my ($self, $cmd) = @_;
	$ssh_->system("$cmd") or die "Failed to execute $cmd: $ssh_->error.\n";
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
