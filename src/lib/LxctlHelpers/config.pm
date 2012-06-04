package LxctlHelpers::config;

use strict;
use warnings;

use YAML::Tiny qw(DumpFile LoadFile);

use Lxc::object;

# @main_config_paths should be hardcoded, at least for now.
my @main_config_paths = ("/etc/lxctl", "/etc", ".");

# Return the pathname of an existing config file to read/write.
# If called with an argument, set the pathname.

sub _pathname {
	my ($self, $pathname) = @_;

	if ($pathname) {
		$self->{'pathname'} = $pathname;
		return;
	}

	$pathname = $self->{'pathname'};

	if ($pathname) {
		return $pathname;
	}

	# Find the first existing file
	foreach my $path (@main_config_paths) {
		my $file = "$path/lxctl.yaml";

		if (-f $file) {
			$self->{'pathname'} = $file;
			return $file;
		}
	}

	return undef;
}

sub print_warn #(message)
{
	use Term::ANSIColor;
	my ($self, $message) = @_;
	print STDERR color 'bold yellow';
	print STDERR "Warning:";
	print STDERR color 'reset';
	print STDERR " $message";
	return 1;
}

sub load_main
{
	my ($self) = @_;

	my $pathname = $self->_pathname() || return;

	my $yaml = YAML::Tiny->new;
	$yaml = YAML::Tiny->read($pathname);

	# For compatibility reasons. Remove somewhere in 0.3+
	eval {
		$self->{'lxc'}->set_roots_path($yaml->[0]->{'paths'}->{'ROOTS_PATH'});
		$self->print_warn("$pathname: ROOTS_PATH is deprecated. Please rename to ROOT_MOUNT_PATH\n");
	} or do {
		$self->{'lxc'}->set_root_mount_path($yaml->[0]->{'paths'}->{'ROOT_MOUNT_PATH'});
	};

	eval {
		$self->{'lxc'}->set_config_path($yaml->[0]->{'paths'}->{'CONFIG_PATH'});
		$self->print_warn("$pathname: CONFIG_PATH is deprecated. Please rename to YAML_CONFIG_PATH\n");
	} or do {
		$self->{'lxc'}->set_yaml_config_path($yaml->[0]->{'paths'}->{'YAML_CONFIG_PATH'});
	};

	$self->{'lxc'}->set_lxc_conf_dir($yaml->[0]->{'paths'}->{'LXC_CONF_DIR'});
	$self->{'lxc'}->set_lxc_log_path($yaml->[0]->{'paths'}->{'LXC_LOG_PATH'});
	$self->{'lxc'}->set_lxc_log_level($yaml->[0]->{'paths'}->{'LXC_LOG_LEVEL'});
	$self->{'lxc'}->set_template_path($yaml->[0]->{'paths'}->{'TEMPLATE_PATH'});
	$self->{'lxc'}->set_vg($yaml->[0]->{'lvm'}->{'VG'});

	my $skip_check = $yaml->[0]->{'check'}->{'skip_kernel_config_check'};
	if (defined($skip_check)) {
		$self->{'lxc'}->set_conf_check($skip_check);
	}
}

sub get_option_from_main #($section, $option_name)
{
	my ($self, $section, $option_name) = @_;
	my $result = '';

	my $pathname = $self->_pathname() || return;

	my $yaml = YAML::Tiny->new;
	$yaml = YAML::Tiny->read($pathname);

	eval {
		$result = $yaml->[0]->{"$section"}->{"$option_name"};
	};

	return $result;
}

sub get_option_from_yaml #($filepath, $section, $option_name)
{
	my ($self, $filepath, $section, $option_name) = @_;
	my $result = undef;
	return $result if (! -f "$filepath");
	my $yaml = YAML::Tiny->new;
	$yaml = YAML::Tiny->read("$filepath");
	eval {
		if ($section ne '') {
			$result = $yaml->[0]->{"$section"}->{"$option_name"};
		} else {
			$result = $yaml->[0]->{"$option_name"};
		}
		1;
	};
	
	return $result;
}

# hash_ref, filename
#  ex: $config->save_hash(\%options, "abrakadabra.yaml");
sub save_hash
{
	my $self = shift;
	my $hash = shift;
	my $filename = shift;

	my %rhash = %$hash;
	DumpFile($filename, \%rhash);

	return;
}

# only arg: filename
#  ex:
#     my $tmp = $config->load_file("abrakadabra.yaml");
#     my %opts = %$tmp;
sub load_file
{
	my $self = shift;
	my $filename = shift;

	my $hash = LoadFile($filename);

	my %h = %$hash;
	$h{'api_ver'} = 0 if (!defined($h{'api_ver'}));
	$hash = \%h;

	return $hash
}

#Current config API version
sub get_api_ver
{
	my $self = shift;

	return 1;
}

# Loads hash from file, then modifies it with hash from 1st arg
# After that writes back to file.
sub change_hash
{
	my $self = shift;
	my $hash = shift;
	my $filename = shift;

	if ( ! -f $filename ) {
		return;
	}

	my $tmp = $self->load_file($filename);
	my %tmp_hash = %$tmp;
	my %rhash = %$hash;

	foreach my $key (sort keys %rhash) {
		$tmp_hash{$key} = $rhash{$key};
	}

	$self->save_hash(\%tmp_hash, $filename);

	return;
}

sub set_option_to_main
{
	my ($self, $section, $option_name, $value) = @_;

	my $pathname = $self->_pathname() || return;

	my $yaml = YAML::Tiny->new;
	$yaml = YAML::Tiny->read($pathname);

	if (defined $value) {
		$yaml->[0]->{$section}->{$option_name} = $value;
	} else {
		delete $yaml->[0]->{$section}->{$option_name};
	}

	$yaml->write($pathname);
}

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{'lxc'} = new Lxc::object;

	return $self;
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
