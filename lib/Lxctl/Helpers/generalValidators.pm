package Lxctl::Helpers::generalValidators;

=pod
=head1 NAME
Lxctl::Helpers::generalValidators - general validator class.

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

General validator class. You should ALWAYS pass default = undef to general validator function

=head1 METHODS
=cut

use warnings;
use strict;
use 5.010001;
use feature "switch";
use Data::UUID;
use Data::Dumper;

my $debug = 0;

=pod
B<validate(\%hash, 'key_name', 'type', $default_value, @optional_arguments)>
  or
B<validate(\$scalar, undef, 'type', $default_value, @optional_arguments)>

General validator function. Validates hash. Default value SHOULD  be undef if it's not needed

Avaliable types:
s|str|string
i|int|integer
b|bool|boolean
e|enum
d|dir|directory
S|size|Size
=cut

sub validate
{
	my $self = shift;
	my $hash = shift;
	my $key = shift;
	my $type = shift;
	my $default = shift;
	my %local_hash = ();
	if (ref($hash) eq "HASH") {
		print "Hash...\n";
		$local_hash{'val'} = $hash->{"$key"};
	} elsif (ref($hash) eq "ARRAY") {
		print "Wow! Array ref\n";
		$local_hash{'val'} = $hash;
	} else {
		$local_hash{'val'} = ${$hash};
	}

	my $real_default = $default;
	if (ref($default) eq "CODE") {
		$real_default = &$default();
	}

	print "   DEBUG: validate: $type\n" if ($debug >= 2);
	given ($type) {
		when (/^(s|str|string)$/) {
			print "   DEBUG: validate: validating '$type' as STRING\n" if ($debug >= 2);
			$self->defaultString(\%local_hash, 'val', $real_default);
		}
		when (/^(i|int|integer)$/) {
			print "   DEBUG: validate: validating '$type' as INT\n" if ($debug >= 2);
			$self->defaultInt(\%local_hash, 'val', $real_default);
		}
		when (/^(b|bool|boolean)$/) {
			print "   DEBUG: validate: validating '$type' as BOOL\n" if ($debug >= 2);
			$self->defaultBool(\%local_hash, 'val', $real_default);
		}
		when (/^(e|enum)$/) {
			print "   DEBUG: validate: validating '$type' as ENUM\n" if ($debug >= 2);
			$self->defaultEnum(\%local_hash, 'val', $real_default, @_);
		}
		when (/^(d|dir|directory)$/) {
			print "   DEBUG: validate: validating '$type' as DIR\n" if ($debug >= 2);
			my ($exists) = @_;
			$self->defaultDir(\%local_hash, 'val', $real_default, $exists);
		}
		when (/^(S|size|Size)$/) {
			print "   DEBUG: validate: validating '$type' as SIZE\n" if ($debug >= 2);
			$self->defaultSize(\%local_hash, 'val', $real_default);
		}
		when (/^(U|UUID|uuid)$/) {
			print "   DEBUG: validate: validating '$type' as UUID\n" if ($debug >= 2);
			$self->defaultUUID(\%local_hash, 'val', $real_default, shift);
		}
		when (/^(m|mac)$/) {
			print "   DEBUG: validate: validating '$type' as MAC\n" if ($debug >= 2);
			$self->defaultMAC(\%local_hash, 'val', $real_default);
		}
		when (/^(ipv4|IPv4|IPV4)$/) {
			print "   DEBUG: validate: validating '$type' as IPv4\n" if ($debug >= 2);
			$self->defaultIPv4(\%local_hash, 'val', $real_default);
		}
		when (/^(a|array)$/) {
			print "   DEBUG: validate: validating '$type' as ARRAY\n" if ($debug >= 2);
			$self->defaultArray(\%local_hash, 'val', $real_default);
		}
		default {
			die "Unknown type";
		}
	}

	if (ref($hash) eq "HASH") {
		$hash->{"$key"} = $local_hash{'val'};
	} elsif (ref($hash) eq "ARRAY") {
		@{$hash} = @{$local_hash{'val'}};
	} else {
		${$hash} = $local_hash{'val'};
	}
}

sub defaultArray
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultString: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate($default, undef, 'array');
			@{$hash->{$key}} = @{$default};
		}
		return
	}
	foreach my $val (@{$hash->{$key}}) {
		if ($val !~ m/^([a-zA-Z0-9_.,'"\*\/\-=:]|\s)*$/) {
			die "Incorrect value: '$val'.\n";
		}
	}
}

sub defaultMAC
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultString: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'mac');
			$hash->{$key} = $default;
		}
	} elsif ($hash->{$key} !~ m/^([a-fA-F0-9]{2}:){4}[a-fA-F0-9]{2}$/) {
		die "Incorrect value: '$hash->{$key}'.\n";
	}
}

sub defaultIPv4
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultString: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'ipv4');
			$hash->{$key} = $default;
		}
	} elsif ($hash->{$key} !~ m/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/) {
		die "Incorrect value: '$hash->{$key}'.\n";
	}
}


sub defaultUUID
{
	my ($self, $hash, $key, $gen) = @_;

	if (!defined($hash->{$key})) {
		if (!defined($gen)) {
			die "$key is not defined.\n";
		}
		if ($gen eq 0) {
			die "$key is not defined.\n";
		}
		my $ug = new Data::UUID;
		$hash->{$key} = $ug->create_str();
	} elsif ($hash->{"$key"} !~ m/[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultEnum
{
	my ($self, $hash, $key, $default, @values) = @_;
	print "     DEBUG: defaultEnum: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'enum', undef, @values);
			$hash->{$key} = $default;
		}
	} elsif (! grep { $_ eq $hash->{$key}} @values) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultInt
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultInt: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'int');
			$hash->{$key} = $default;
		}
	} elsif ($hash->{$key} !~ m/^[0-9]+$/) {
		die "Incorrect value '$hash->{$key}'.\n";
	}
}

sub defaultBool
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultBool: $key, $default\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'bool');
			$hash->{$key} = $default;
		}
	} elsif (lc($hash->{$key}) !~ m/^(1|0|true|false)$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultString
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultString: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'str');
			$hash->{$key} = $default;
		}
	} elsif ($hash->{$key} !~ m/^([a-zA-Z0-9_.,'"\*\/\-=:]|\s)*$/) {
		die "Incorrect value: '$hash->{$key}'.\n";
	}
}

sub defaultDir
{
	my ($self, $hash, $key, $default, $exists) = @_;
	if (!defined($exists)) {
		$exists = 1;
	}
	print "     DEBUG: defaultDir: $key, $default\n" if ($debug >= 1);

	$self->defaultString($hash, $key, $default);
	if ((! -d "$hash->{$key}") && ($exists == 1)) {
		die "No such directory $hash->{$key}.\n";
	}
}

sub defaultSize
{
	my ($self, $hash, $key, $default) = @_;
	print "     DEBUG: defaultSize: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->validate(\$default, undef, 'size');
			$hash->{$key} = $default;
		}
	} elsif ($hash->{$key} !~ m/^([0-9]*.)?[0-9]+[bBkKmMgGtTpPeE]?$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub new
{
        my $parent = shift;
        my $self = {};
        bless $self, $parent;
	my $debug_tmp = shift;
	$debug = $debug_tmp if (defined($debug_tmp));

	return $self;
}

1;
