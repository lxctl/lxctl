package Lxctl::Helpers::generalValidators;

my $debug = 1;

sub defaultEnum
{
	my ($self, $hash, $key, $default, @values) = @_;
	print "DEBUG: defaultEnum: $key, $default\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! grep { $_ eq $hash->{$key}} @values) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultInt
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultInt: $key, $default\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! $hash->{$key} =~ m/^[0-9]+$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultString
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultString: $key, $default\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! ($hash->{$key} =~ m/^([a-zA-Z0-9_.,'"\*\/\-]|\s)*$/)) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub defaultDir
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultDir: $key, $default\n" if ($debug == 1);

	$self->defaultString($hash, $key, $default);
	if (! -d "$hash->{$key}") {
		die "No such directory $hash->{$key}.\n";
	}
}

sub defaultSize
{
	my ($self, $hash, $key, $default) = @_;
	print "DEBUG: defaultSize: $key, $default\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		$hash->{$key} = $default;
	} elsif (! $hash->{$key} =~ m/^([0-9]*.)?[0-9]+[bBkKmMgGtTpPeE]?$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub enum
{
	my ($self, $hash, $key, @values) = @_;
	print "DEBUG: enum: $key\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		die "$key is not defined.\n";
	}

	if (! grep { $_ eq $hash->{$key}} @values) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub int
{
	my ($self, $hash, $key) = @_;
	print "DEBUG: int: $key\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		die "$key is not defined.\n";
	}

	if (! $hash->{$key} =~ m/^[0-9]+$/) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub string
{
	my ($self, $hash, $key) = @_;
	print "DEBUG: string: $key\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		die "$key is not defined.\n";
	}

	if (! ($hash->{$key} =~ m/^([a-zA-Z0-9_.,'"\*\/\-]|\s)*$/)) {
		die "Incorrect value $hash->{$key}.\n";
	}
}

sub dir
{
	my ($self, $hash, $key) = @_;
	print "DEBUG: dir: $key\n" if ($debug == 1);

	$self->string($hash, $key, $default);
	if (! -d "$hash->{$key}") {
		die "No such directory $hash->{$key}.\n";
	}
}

sub size
{
	my ($self, $hash, $key) = @_;
	print "DEBUG: size: $key\n" if ($debug == 1);

	if (!defined($hash->{$key})) {
		die "$key is not defined.\n";
	}

	if (! $hash->{$key} =~ m/^([0-9]*.)?[0-9]+[bBkKmMgGtTpPeE]?$/) {
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
