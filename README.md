lxctl
=====

perl program to control lxc-based containers in vzctl-like way.

Contributing
------------

http://bugs.lxc.tl/

Usage
-----

    $ lxctl --help
or
    $ lxctl --man

<pre>
$ lxctl --help
Usage:
    lxctl [action] [vmname] [options]

    See lxctl --help for more info

Options:
    --help  Print a brief help message and exit

    start   Starts container specified in 1st argument

            Required arguments:

                    vmname - name of the container

    stop    Stops container specified in 1st argument

            Required arguments:

                    vmname - name of the container

    create  Creates container.

            Required arguments:

                    vmname - name of the container

            Optional arguments:

                    --ipaddr - IP address of the machine

                    --mask/netmask - network mask of the machine

                    --defgw - default gateway of the machine

                    --dns - primary DNS server

                    --ostemplate - template name, by default it is 'lucid_amd64'

                    --config - path to configuration file, by default /etc/lxc/<container name> is used

                    --root - path to root file system, by default /var/lxc/<container name> is used

                    --roottype - storage type for root file system. Available values: 
                        lvm (default)   - create new logical value on default VG
                        file            - create disk image on host FS
                        raw             - use raw device specified by '--device' option

                    --addpkg - list of additional packages (comma-separated)

                    --pkgopt - list of additional packet manager options (space-separated, but as one argument)

                    --rootsz - size of logical volume for root FS, by default it is 10G

                    --hostname - sets the hostname of the machine, by default <container name> is used

                    --searchdomain - set a custom searchdomain in /etc/resolv.conf

                    --macaddr - set the custom mac address of the container

                    --autostart - autostart container each reboot host machine

                    --no-save - do not save yaml config for new container, by default $CONF_PATH/vmname.yaml is used

                    --load - create container from yaml config

                    --debug - show more information about install process

                    --tz - set custom timezone (Europe/Moscow, UTC, etc)

                    --empty - create a clear container for migrate here

    set     Changes container parameters.

            Required arguments:

                    vmname - name of the container

            Optional arguments:

                    --rootsz - increment of size of logical volume for root FS

                    --ipaddr - IP address if the machine

                    --mask/netmask - network mask of the machine

                    --defgw - default gateway of the machine

                    --dns - primary DNS server

                    --hostname - sets the hostname of the machine

                    --searchdomain - set a custom searchdomain in /etc/resolv.conf

                    --macaddr - set the custom mac address if the machine

                    --userpasswd user:passwd - sets password for given user

                    --onboot {yes,no} - makes container [do not] start at boot

                    --tz - set custom timezone (Europe/Moscow, UTC, etc)

                    --cpu-shares - sets the CPU share of the container

                    --cpus - sets the CPU cores of the container

                    --mem - sets the memory share of the container (in bytes!)

                    --io - sets the IO share of the container

    freeze  Freezes container

            Required arguments:

                    vmname - name of the container

    unfreeze
            Unfreezes container

            Required arguments:

                    vmname - name of the container

    list    Lists all containers

            Optional arguments:

                    --ipaddr - display with IP addr

                    --hostname - display with hostname.

                    --cgroup - display with cgroup

                    --mount - display with mount point for rootfs

                    --diskspace - display with free/full size

                    --all - display all information

                    --raw - display only vmnames

    migrate Migrate container from localhost to remote host.

            Required arguments

                    --tohost - to which host we should migrate

            Optional arguments

                    --remuser - remote username for ssh

                    --remport - remote port for ssh

                    --remname - remote container name

                    --onboot - start on boot? 1 or 0

                    --userpasswd - 'user:password' formatted password for user

                    --clone - cloning, a little bit faster and softer then simple migration

                    --rootsz - remote root fs size

                    --afterstart - start local container again after migration

                    --cpus - cpus allocated to container

                    --cpu-shares - cpu time share of the container

                    --mem - memory limit of the container

                    --io - IO throughput

                    --ipaddr - IP of the remote container

                    --searchdomain - DNS search domain of the container

                    --netmask - network mask

                    --defgw - default gateway

                    --dns - DNS server

    backup  Create or restore backup container with use remote host.

            Required arguments for create backup

                    --create - create backup

                    --tohost - remote host for store backup

                    --todir - remote dir for store backup

            Required arguments for restore backup

                    --restore - restore backup

                    --fromhost - remote host from restore backup

                    --fromdir - remote dir from restore backup

            Optional arguments

                    --remuser - remote username for ssh

                    --remport - remote port for ssh

                    --remname - remote container name

                    --userpasswd - 'user:password' formatted password for user
        
                    --afterstart - start local container after restore backup

    vz2lxc  Migrate VZ-container from remote host to local LXC container.

            Required arguments

                    --fromhost - from which host we should migrate

                    --remname - remote container name

            Optional arguments

                    --remuser - remote username for ssh

                    --remport - remote port for ssh

                    --onboot - start on boot? 1 or 0

                    --rootsz - remote root fs size

                    --afterstart - start local container again after migration

                    --cpus - cpus allocated to container

                    --cpu-shares - cpu time share of the container

                    --mem - memory limit of the container

                    --io - IO throughput
</pre>

Contributing
------------

Feel free to contact us via email:

Anatoly Burtsev, anatolyburtsev@yandex.ru

Pavel Potapenkov, ppotapenkov@gmail.com

Vladimir Smirnov, civil.over@gmail.com

Copyrighting and License
------------------------

Copyright (C) 2011 by Anatoly Burtsev, Pavel Potapenkov, Vladimir Smirnov

This script is free software; you can redistribute it and/or modify
it under the same terms of GPL v2 or later, or, at your opinion
under terms of artistic license.

