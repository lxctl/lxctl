package Lxctl::helpers::_plugins;
# In fact it is almost 100% pure copy of Module::Pluggable::Ordered with one
# change: now all parameters passed to constructor of a new class. Maybe it
#  won't work with none-OOP code, but works quite well for our purpoes.

# See http://search.cpan.org/~apeiron/Module-Pluggable-Ordered-1.5/Ordered.pm
# for original information

# I really regret this ugliness, but it's needed in the face of backwards
# compatibility, and I don't want "code this funky" wandering around CPAN
# without warnings if I can help it. :) Those using ancient versions of Perl can
# use -w for global warnings. Unfortunately, there's not much else I can do. If
# anyone has any suggestions, please do file a bug report. Thanks.

BEGIN 
{
	if($] >= 5.00600)
	{
		require warnings;
		import warnings;
	}
}
use strict;
require Module::Pluggable;
use UNIVERSAL::require;
use vars qw($VERSION);
$VERSION = '1.5';

sub import {
    my ($self, %args) = @_;
    my $subname = $args{sub_name} || "plugins";

	my %only;
	my %except;

    %only   = map { $_ => 1 } @{$args{'only'}}    if defined $args{'only'};
    %except = map { $_ => 1 } @{$args{'$except'}} if defined $args{'except'};

    my $caller = $args{package} || caller;
	
    no strict; 

    *{"${caller}::call_plugins"} = sub {
        my ($thing, $name, @args)  = @_;
        my @plugins = ();
        for ($thing->$subname()) {
            next if (keys %only   && !$only{$_}   );
            next if (keys %except &&  $except{$_} );
            push @plugins, $_;
        }
            
        $_->require for @plugins;

        my $order_name = "${name}_order";
        for my $class (sort { $a->$order_name() <=> $b->$order_name() }
                       grep { $_->can($order_name) }
                       @plugins) {
            $class->$name(@args);
        }
    };

    *{"${caller}::${subname}_ordered"} = sub {
        my $thing  = shift;

		my @plugins = $thing->$subname(@_);
		$_->require for @plugins;

		return	map  { $_->[0] }
				sort { $a->[1] <=> $b->[1] }
				map  { [ $_, ( $_->can('_order') ? $_->_order : 50 ) ] }
				@plugins;
	};
		
    goto &Module::Pluggable::import;
}

1;
__END__

=head1 NAME

Module::Pluggable::Ordered - Call module plugins in a specified order

=head1 SYNOPSIS

    package Foo;
    use Module::Pluggable::Ordered;

    Foo->call_plugins("some_event", @stuff);

	for my $plugin (Foo->plugins()){
		$plugin->method();
	}

Meanwhile, in a nearby module...

    package Foo::Plugin::One;
    sub some_event_order { 99 } # I get called last of all
    sub some_event { my ($self, @stuff) = @_; warn "Hello!" }

	sub _order { 99 } # I get listed by plugins_ordered() last

And in another:

    package Foo::Plugin::Two;
    sub some_event_order { 13 } # I get called relatively early
    sub some_event { ... }

	sub _order { 10 } # I get listed by plugins_ordered() early

=head1 DESCRIPTION

This module behaves exactly the same as C<Module::Pluggable>, supporting all of
its options, but also mixes in the C<call_plugins> and C<plugins_ordered>
methods to your class. C<call_plugins> acts a little like C<Class::Trigger>; it
takes the name of a method, and some parameters. Let's say we call it like so:

    __PACKAGE__->call_plugins("my_method", @something);

C<call_plugins> looks at the plugin modules found using C<Module::Pluggable> 
for ones which provide C<my_method_order>. It sorts the modules
numerically based on the result of this method, and then calls
C<$_-E<gt>my_method(@something)> on them in order. This produces an
effect a little like the System V init process, where files can specify
where in the init sequence they want to be called.

C<plugins_ordered> extends the C<plugins> method created by
C<Module::Pluggable> to list the plugins in defined order. It looks for
a C<_order> method in the modules found using C<Module::Pluggable>, and
returns the modules sorted numerically in that order. For example:

	my @plugins = __PACKAGE__->plugins();

The resulting array of plugins will be sorted. If no C<_order> subroutine
is defined for a module, an arbitrary default value of 50 is used.

=head1 OPTIONS

The C<package> option can be used to put the pluggability into another
package, to be used for modules building on the functionality of this
one.

It also provides the C<only> and C<except> options.

     # will only return the Foo::Plugin::Quux plugin
     use Module::Pluggable::Ordered only => [ "Foo::Plugin::Quux" ];

     # will not return the Foo::Plugin::Quux plugin
     use Module::Pluggable::Ordered except => [ "Foo::Plugin::Quux" ];


=head1 SEE ALSO

L<Module::Pluggable>, L<Class::Trigger>

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt> (author emeritus)

Christopher Nehren, E<lt>apeiron@cpan.orgE<gt> (current maintainer)

Vladimir Smirnov, E<lt>civil.over@gmail.comE<gt> (only this fork)

For original module, please, visit:
http://search.cpan.org/~apeiron/Module-Pluggable-Ordered-1.5/Ordered.pm

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

Copyright 2004 by Christopher Nehren (current copyright holder)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 ACKNOWLEDGEMENTS

Thank you to Simon Cozens for originally writing this module.

Thanks to Lars Thegler for indirectly alerting me to the fact that my POD was
horribly broken, for providing patches to make this module work with Perl
versions < 5.6, for maintaining the port up to version 1.3, and for allowing me
to take maintainership for versions 1.3 onwards.

=cut
