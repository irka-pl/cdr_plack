package GhostFW::API::Base;
use strict;
use warnings;

#conflicts with http method get
use parent qw(Class::Accessor);
use GhostFW::DB;
use GhostFW::Utils qw(resource_from_classname);
#todo: check plack middleware to convert on the flight
use JSON;


__PACKAGE__->mk_ro_accessors( qw(app logger config) );
#TODO: Model read only
__PACKAGE__->mk_accessors( qw(request response resource model) );

sub new{
    my ($class, $app, $request, $response) = @_;
    my $config;
    {
        no strict 'refs';
        #todo: prevent base class instantiation
        $config = ${$class."::config"};
    }
    my $data = {
        app      => $app,
        request  => $request,
        response => $response,
        #shortcut to app logger
        logger   => $app->logger,
        config   => $config,
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

sub error {
    my ($self, $error) = @_;
    $self->logger->debug($error->{message});
    if($error->{log}) {
        $self->logger->debug($error->{log});
    }
    $self->response->status($error->{code});
    $self->response->body('');
    die();
}

sub handle_method {
    my $self = shift;
    my($method) = @_;
    $method = uc($method);
    my $method_base = 'base_'.$method;
    unless($self->can($method) || $self->can($method_base)) {
        return;
    }
    if ( $self->can($method_base) ) {
        $self->$method_base(@_);
    }
    if ( $self->can($method) ) {
        $self->$method(@_);
    }
    return 1;
}

sub base_POST {
    #data validation here
}

sub base_GET {
    my($self) = @_;
    my $filter = $self->get_filter_from_params;
    my $data = $self->model()->get_list($filter);
    #todo: repetition: look at the plack middlewares for output postprocessing
    $self->response->body(encode_json ($data));
    $self->response->status(200);
}

sub get_filter_from_params {
    my ($self) = shift;
    my $params = $self->request->parameters;
    my $filter = {};
    foreach my $filter_param (keys %{$params} ) {
        my $filter_field = $filter_param;
        if ($filter_field =~ s/^filter_//) {
            #op examples: eq, le, ge, lt, gt, in, like, period
            (my($op,$field)) = ( $filter_field =~ /(^[^_]+)_(.*)$/ );
            $filter->{$field}->{$op} = [$self->request->parameters->get_all($filter_param)];
        }
    }
    return $filter;
}
1;