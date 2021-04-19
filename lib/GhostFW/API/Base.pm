package GhostFW::API::Base;
use strict;
use warnings;

#conflicts with http method get
use parent qw(Class::Accessor);
use GhostFW::DB;
use GhostFW::Utils qw(resource_from_classname);

__PACKAGE__->mk_ro_accessors( qw(app logger) );
#TODO: Model read only
__PACKAGE__->mk_accessors( qw(request response resource model) );

sub new{
    my ($class, $app, $request, $response) = @_;
    my $data = {
        app      => $app,
        request  => $request,
        response => $response,
        #shortcut to app logger
        logger   => $app->logger,
    };
    $app->logger->debug( "Creating new API Resource $class.");
    my $self = bless $data, $class;
    #TODO: config
    $self->resource($self->can('_resource') 
        ? $self->_resource 
        : resource_from_classname($class));
    $app->logger->debug( 'Resource: '.$self->resource);
    $self->model($app->model($self->resource, $self));

    return $self;
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