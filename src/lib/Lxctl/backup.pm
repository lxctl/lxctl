package Lxctl::backup;

use strict;
use warnings;

use Getopt::Long;
use Lxc::object;
use LxctlHelpers::config;
use LxctlHelpers::SSH;

my %options = ();

my $yaml_conf_dir;
my $lxc_conf_dir;
my $root_mount_path;
my $templates_path;
my $vg;

my $ssh;

my $rsync_opts;
my $config;
my $host;

sub backup_get_opt
{
    my $self = shift;
    
    GetOptions(\%options, 
        'create!',  'tohost=s', 'todir=s', 'restore!', 'fromhost=s', 'fromdir=s', 'remuser=s', 'remname=s', 'afterstart!');

    $options{'remuser'} ||= 'root';
    $options{'remport'} ||= '22';
    $options{'remname'} ||= $options{'contname'};
    $options{'afterstart'} ||= 0;
    $options{'create'} ||= 0;
    $options{'restore'} ||= 0;
    if ($options{'create'}) {
        defined($options{'tohost'}) or 
        die "Set remote host (--tohost) parameter!\n\n";
        $host = $options{'tohost'};
        defined($options{'todir'}) or 
        die "Set remote dir (--todir) parameter!\n\n";
    }
    
    if ($options{'restore'}) {
        defined($options{'fromhost'}) or 
        die "Set remote host (--fromhost) parameter!\n\n";
        $host = $options{'fromhost'};
        defined($options{'fromdir'}) or 
        die "Remote dir (--fromdir) parameter!\n\n";
    }
    
    $ssh = LxctlHelpers::SSH->connect($host, $options{'remuser'}, $options{'remport'});
}

sub re_rsync
{
    my $self = shift;
    my $first_pass = shift;
    my $status;

    eval {
        $status = $self->{'lxc'}->status($options{'contname'});
    } or do {
        die "Failed to get status for container $options{'contname'}!\n\n";
    };

    if ($status ne 'RUNNING') {
        return if $first_pass;
        die "Aborting due to rsync error.\n\n" if !$first_pass;
    }

    eval {
        print "Stopping container $options{'contname'}...\n";
        $self->{'lxc'}->stop($options{'contname'});
    } or do {
        die "Failed to stop container $options{'contname'}.\n\n";
    };

    print "Start second rsync pass...\n";
    $self->sync_data()
        or die "Failed to finish second rsinc pass.\n\n";
}

sub copy_config
{
    my $self = shift;
    if ($options{'create'}) {
        print "Sending config to $options{'tohost'}...\n";
        $ssh->put_file("$yaml_conf_dir/$options{'contname'}.yaml", "$options{'todir'}/$options{'contname'}.yaml");
    }
    if ($options{'restore'}) {
        print "Copy backup config from $options{'fromhost'}...\n";
        $ssh->get_file("$options{'fromdir'}/$options{'contname'}.yaml", "/tmp/$options{'contname'}.yaml");
    }
}

sub sync_data {
    my $self = shift;
    my $ret;
    if ($options{'create'}) {
        $rsync_opts = $config->get_option_from_main('rsync', 'RSYNC_OPTS');
        my $rsync_from = "$root_mount_path/$options{'contname'}/";
        my $rsync_to = "$options{'remuser'}\@$options{'tohost'}:$options{'todir'}/$options{'contname'}";
        $ret = !system("rsync $rsync_opts $rsync_from $rsync_to")
            or print "There were some problems during syncing root filesystem. It's ok if this is the first pass.\n\n";
    }
    if ($options{'restore'}) {
        $rsync_opts = $config->get_option_from_main('rsync', 'RSYNC_OPTS');
        my $rsync_from = "$options{'remuser'}\@$options{'fromhost'}:$options{'fromdir'}/$options{'contname'}/";
        my $rsync_to = "$root_mount_path/$options{'contname'}";
        $ret = !system("rsync $rsync_opts $rsync_from $rsync_to")
            or print "There were some problems during syncing root filesystem. It's ok if this is the first pass.\n\n";
    }
    return $ret;
}

sub create_backup
{
    my $self = shift;
    print "Creating remote dir...\n";
    $ssh->execute("mkdir -p $options{'todir'}/$options{'contname'}")
        or die "Failed to create remote dir.\n\n";
    $self->copy_config();
    print "Creating backup...\n";

    print "Start first rsync pass...\n";
    my $first_pass = $self->sync_data();

    $self->re_rsync($first_pass);
    
}

sub restore_backup
{
    my $self = shift;
    
    $self->copy_config();

    print "Creating container...\n";
    
    !system("lxctl create $options{'contname'} --empty --load /tmp/$options{'contname'}.yaml")
        or die "Failed to create container for restore.\n\n";

    print "Start rsync pass...\n";
    $self->sync_data();
    
}

sub do
{
    my $self = shift;
    $options{'contname'} = shift
        or die "Name the container please!\n\n";

    $self->backup_get_opt();
    if ($options{'create'}) {
        $self->create_backup();
        system("lxctl start $options{'contname'}");
    } elsif ($options{'restore'}) {
        $self->restore_backup();
        eval {
            #Next line is a very ugly and useful only for us hack. Don't pay any attention to it.
            !system("ls /usr/lib/perl/5.10/Lxctl/conduct.pm 1>/dev/null 2>/dev/null && lxctl conduct $options{'remname'}");
        } or do {
            print "Lxctl conduct error...\n";
        };
        if ($options{'afterstart'}) {
            system("lxctl start $options{'contname'}");
        }
    } else {
        print "Set --create or --restore parameter.\n";
    }
    
}

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->{lxc} = new Lxc::object;

    $root_mount_path = $self->{'lxc'}->get_roots_path();
    $templates_path = $self->{'lxc'}->get_template_path();
    $yaml_conf_dir = $self->{'lxc'}->get_config_path();
    $lxc_conf_dir = $self->{'lxc'}->get_lxc_conf_dir();
    $config = new LxctlHelpers::config;

    return $self;
}

1;
__END__

=head1 AUTHOR

Eugene Kilimchuk, E<lt>ekilimchuk@yandex.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Eugene Kilimchuk

This library is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

=cut
