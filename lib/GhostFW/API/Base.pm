package GhostFW::API::Base;
use strict;
use warnings;

#conflicts with http method get
use parent qw(Class::Accessor);
use GhostFW::DB;

__PACKAGE__->mk_ro_accessors( qw(app request response logger resource) );

sub new{
    my ($class, $app, $request, $response) = @_;
    my $data = {
        app      => $app,
        request  => $request,
        response => $response,
        #shortcut to app logger
        logger   => $app->logger,
        #TODO: config
        resource => undef,
    };
    $app->logger->debug( "Creating new API Resource $class.");
    return bless $data, $class;
}

sub handle_method {
    my $self = shift;
    my($method) = @_;
    $method = uc($method);
    unless($self->can($method)) {
        return;
    }
    my $method_base = 'base_'.$method;
    if ( $self->can($method_base) ) {
        $self->$method_base(@_);
    }
    $self->$method(@_);
}

1;