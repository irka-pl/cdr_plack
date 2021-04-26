package GhostFW::API::Base;
use strict;
use warnings;

#conflicts with http method get
use parent qw(Class::Accessor);
use GhostFW::DB;
use GhostFW::Utils qw(resource_from_classname);

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
    unless($self->can($method)) {
        return;
    }
    my $method_base = 'base_'.$method;
    if ( $self->can($method_base) ) {
        $self->$method_base(@_);
    }
    $self->$method(@_);
}

sub base_POST {
    #data validation here
}

sub get_filter_from_params {
    my ($self) = shift;
    my $params = $self->request->params;
    my $filter = {};
    foreach my $filter_param (keys %{$params} ) {
        my $filter_field = $filter_param;
        if ($filter_field =~ s/^filter_//) {
            #op examples: eq, le, ge, lt, gt, in, like, period
            (my($op,$field)) = $filter_field =~ /(^[^_]+)_(.*?)/;
            if ($filter->{$field}->{$op}) {
                push @{$filter->{$field}->{$op}}, $params->{$filter_param};
            } else {
                $filter->{$field}->{$op} = $params->{$filter_param};
            }
        }
    }
    return $filter;
}
1;