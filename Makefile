install:
	install -D lxctl $(DESTDIR)/usr/bin/lxctl
	install -D lxctl.yaml $(DESTDIR)/etc/lxctl/lxctl.yaml
	install -D bash_completion.d/lxctl $(DESTDIR)/etc/bash_completion.d/lxctl
	install -D bash_completion.d/lxctl_create $(DESTDIR)/etc/bash_completion.d/lxctl_create
	install -D bash_completion.d/lxctl_destroy $(DESTDIR)/etc/bash_completion.d/lxctl_destroy
	install -D bash_completion.d/lxctl_enter $(DESTDIR)/etc/bash_completion.d/lxctl_enter
	install -D bash_completion.d/lxctl_freeze $(DESTDIR)/etc/bash_completion.d/lxctl_freeze
	install -D bash_completion.d/lxctl_list $(DESTDIR)/etc/bash_completion.d/lxctl_list
	install -D bash_completion.d/lxctl_migrate $(DESTDIR)/etc/bash_completion.d/lxctl_migrate
	install -D bash_completion.d/lxctl_mount $(DESTDIR)/etc/bash_completion.d/lxctl_mount
	install -D bash_completion.d/lxctl_restart $(DESTDIR)/etc/bash_completion.d/lxctl_restart
	install -D bash_completion.d/lxctl_set $(DESTDIR)/etc/bash_completion.d/lxctl_set
	install -D bash_completion.d/lxctl_start $(DESTDIR)/etc/bash_completion.d/lxctl_start
	install -D bash_completion.d/lxctl_stop $(DESTDIR)/etc/bash_completion.d/lxctl_stop
	install -D bash_completion.d/lxctl_unfreeze $(DESTDIR)/etc/bash_completion.d/lxctl_unfreeze
	install -D bash_completion.d/lxctl_pid $(DESTDIR)/etc/bash_completion.d/lxctl_pid
	install -D bash_completion.d/lxctl_vz2lxc $(DESTDIR)/etc/bash_completion.d/lxctl_vz2lxc
	
	install -d $(DESTDIR)/usr/lib/perl/5.10/Lxc
	install -d $(DESTDIR)/usr/lib/perl/5.10/Lxctl
	install -d $(DESTDIR)/usr/lib/perl/5.10/Lxctl/Helpers
	install -d $(DESTDIR)/usr/lib/perl/5.10/LxctlHelpers
	install -d $(DESTDIR)/var/lxc/templates
	install -d $(DESTDIR)/var/lxc/root
	
	cp Lxc/* $(DESTDIR)/usr/lib/perl/5.10/Lxc
	cp Lxctl/*.pm $(DESTDIR)/usr/lib/perl/5.10/Lxctl
	cp Lxctl/Helpers/*.pm $(DESTDIR)/usr/lib/perl/5.10/Lxctl/Helpers
	cp LxctlHelpers/*.pm $(DESTDIR)/usr/lib/perl/5.10/LxctlHelpers
