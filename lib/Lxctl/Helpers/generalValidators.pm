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
	my ($self, $hash, $key, $type, $default) = @_;
	my %local_hash = ();
	if (ref($hash) ne "HASH") {
		$local_hash{'val'} = ${$hash};
	} else {
		$local_hash{'val'} = $hash->{"$key"};
	}

	given ($type) {
		when (/(s|str|string)/) {
			$self->defaultString(\%local_hash, 'val', $default);
		}
		when (/(i|int|integer)/) {
			$self->defaultInt(\%local_hash, 'val', $default);
		}
		when (/(b|bool|boolean)/) {
			$self->defaultBool(\%local_hash, 'val', $default);
		}
		when (/(e|enum)/) {
			$self->defaultEnum(\%local_hash, 'val', $default, @_);
		}
		when (/(d|dir|directory)/) {
			my ($exists) = @_;
			$self->defaultDir(\%local_hash, 'val', $default, $exists);
		}
		when (/(S|size|Size)/) {
			$self->defaultSize(\%local_hash, 'val', $default);
		}
		when (/(U|UUID|uuid)/) {
			$self->defaultUUID(\%local_hash, 'val', $default);
		}
		default {
			die "Unknown type";
		}
	}

	if (ref($hash) ne "HASH") {
		${$hash} = $local_hash{'val'};
	} else {
		$hash->{"$key"} = $local_hash{'val'};
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
	} elsif (! $hash->{"$key"} =~ m/[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+-[a-fA-F0-9]+/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultEnum
{
	my ($self, $hash, $key, $default, @values) = @_;
	print "DEBUG: defaultEnum: $key, $default\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$hash->{$key} = $default;
		}
	} elsif (! grep { $_ eq $hash->{$key}} @values) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultInt
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultInt: $key, $default\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$hash->{$key} = $default;
		}
	} elsif (! $hash->{$key} =~ m/^[0-9]+$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultBool
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultBool: $key, $default\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$hash->{$key} = $default;
		}
	} elsif (! lc($hash->{$key}) =~ m/^(1|0|true|false)$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultString
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultString: $key\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$hash->{$key} = $default;
		}
	} elsif (! ($hash->{$key} =~ m/^([a-zA-Z0-9_.,'"\*\/\-]|\s)*$/)) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultDir
{
	my ($self, $hash, $key, $default, $exists) = @_;
	if (!defined($exists)) {
		$exists = 1;
	}
	print "DEBUG: defaultDir: $key, $default\n" if ($debug >= 1);

	$self->defaultString($hash, $key, $default);
	if ((! -d "$hash->{$key}") && ($exists == 1)) {
		die "No such directory $hash->{$key}.\n";
	}
}

sub defaultSize
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultSize: $key, $default\n" if ($debug >= 1);

	if (!defined($hash->{$key})) {
		if (!defined($default)) {
			die "$key is not defined.\n";
		} else {
			$self->defaultSize($default);
			$hash->{$key} = $default;
		}
	} elsif (! $hash->{$key} =~ m/^([0-9]*.)?[0-9]+[bBkKmMgGtTpPeE]?$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub new
{
        my $parent = shift;
        my $self = {};
        bless $self, $parent;
	$debug = shift;
	$debug = 1 if (!defined($debug));

	return $self;
}

1;
