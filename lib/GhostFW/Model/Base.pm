package GhostFW::Model::Base;
use strict;
use warnings;

use parent qw(Class::Accessor);
use Try::Tiny;
use Module::Runtime qw(use_module);
use GhostFW::Utils qw(resource_from_classname);

__PACKAGE__->mk_ro_accessors( qw(logger controller) );
__PACKAGE__->mk_accessors( qw(resource view db) );


sub new {
    my ($class, $controller) = @_;
    my $data = {
        #TODO: weaken circular reference?
        controller => $controller,
        #shortcuts
        logger     => $controller->logger,
        view       => 'json',
    };
    #$app->logger->debug( "Creating new API Resource $class.");
    my $self = bless $data, $class;
    my $resource = $self->can('_resource') 
            ? $self->_resource 
            : $controller->resource // resource_from_classname($class);
    $self->resource($resource);
    my $db_module_name = $class;
    $db_module_name =~ s/::Model::/::Model::DB::/;
    try {
        $self->logger->debug("Load module '$db_module_name'.");
        my $db = use_module($db_module_name)->new($self);
        $self->db($db);
    } catch {
        $self->logger->debug("Failed to load module '$db_module_name': $_;");
        #todo: throw
    };
    return $self;
}

sub get_list{
    my($self) = @_;
    return $self->db()->get_list();
}

sub get_item{
    my($self, $data) = @_;
    return $self->db()->get_item($data);
}

sub update_item{
    my($self, $key, $data) = @_;
    return $self->db()->update_item($key, $data);
}

sub delete_item{
    my($self, $key) = @_;
    return $self->db()->delete_item($key);
}

sub create_item{
    my($self, $data) = @_;
    return $self->db()->create_item($data);
}

sub delete_items{
    my($self, $keys) = @_;
    return $self->db()->delete_items($keys);
}

sub create_items{
    my($self, $data) = @_;
    return $self->db()->create_items($data);
}


1;