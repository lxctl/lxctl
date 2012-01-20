package Lxctl::Helpers::generalValidators;

sub defaultEnum
{
	my ($self, $var, $default, @values) = @_;

	if (!defined($var)) {
		$var = $default;
	} elsif (! grep { $_ eq $var} @values) {
		die "Incorrect value $var.\n";
	}
}

sub defaultInt
{
	my ($self, $var, $default) = @_;

	if (!defined($var)) {
		$var = $default;
	} elsif (! $var =~ m/^[0-9]+$/) {
		die "Incorrect value $var.\n";
	}
}

sub defaultString
{
	my ($self, $var, $default) = @_;

	if (!defined($var)) {
		$var = $default;
	} elsif (! $var =~ m/^([-^/a-zA-Z0-9_*'"]|\s)*$/) {
		die "Incorrect value $var.\n";
	}
}

sub defaultDir
{
	my ($self, $var, $default) = @_;

	defaultString($var, $default);
	if (! -d "$var") {
		die "No such directory $var.\n";
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
