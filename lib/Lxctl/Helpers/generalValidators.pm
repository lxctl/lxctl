package Lxctl::Helpers::generalValidators;

sub defaultEnum
{
	my ($self, $hash, $key, $default, @values) = @_;

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! grep { $_ eq $hash->{$key}} @values) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultInt
{
	my ($self, $hash, $key, $default) = @_;

	if (!defined($hash->{$key})) {
		$var = $default;
	} elsif (! $hash->{$key} =~ m/^[0-9]+$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultString
{
	my ($self, $hash, $key, $default) = @_;

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! ($hash->{$key} =~ m/^([a-zA-Z0-9_.,'"\*\/\-]|\s)*$/)) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultDir
{
	my ($self, $hash, $key, $default) = @_;

	defaultString($hash, $key, $default);
	if (! -d "$hash->{$key}") {
		die "No such directory $hash->{$key}.\n";
	}
}

sub defaultSize
{
	my ($self, $hash, $key, $default) = @_;

	if (!defined($hash->{$key})) {
		$var = $default;
	} elsif (! $hash->{$key} =~ m/^([0-9]*.)?[0-9]+[bBkKmMgGtTpPeE]?$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub new
{
        my $class = shift;
        my $self = {};
        bless $self, $class;

	return $self;
}

1;
