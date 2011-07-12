DESTDIR=debian/tmp

install:
	install -D lxctl $(DESTDIR)/usr/bin/lxctl
	install -D lxctl $(DESTDIR)/usr/bin/lxctl_debug
	install -D lxctl.yaml $(DESTDIR)/etc/lxctl/lxctl.yaml
	install -D bash_completion.d/lxctl $(DESTDIR)/etc/bash_completion.d/lxctl
	
	install -d $(DESTDIR)/usr/lib/perl/5.10/Lxc
	install -d $(DESTDIR)/usr/lib/perl/5.10/Lxctl
	install -d $(DESTDIR)/var/lxc/templates
	install -d $(DESTDIR)/var/lxc/root
	
	cp Lxc/* $(DESTDIR)/usr/lib/perl/5.10/Lxc
	cp Lxctl/* $(DESTDIR)/usr/lib/perl/5.10/Lxctl
