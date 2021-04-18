package GhostFW::Model::Base;

use parent qw(Class::Accessor);
use Try::Tiny;
use Module::Runtime qw(use_module);
GhostFW::Utils qw/resource_from_classname/;

__PACKAGE__->mk_ro_accessors( qw(app db logger) );


sub new {
    my ($class, $controller) = @_;
    my $db_module_name = $class;
    $db_module_name = s/::Model::([^:]+)$/::Model::DB::$1/;
    my $resource = lc($1);
    try {
        $self->logger->debug("Load module '$db_module_name'.");
        $db = use_module($db_module_name)->new($self);
    } catch {
        $self->logger->error("Failed to load module '$module': $_;");
        $self->error_not_found($response);
    };
    my $data = {
        controller => $controller,
        db         => $db,
        #shortcuts
        logger     => $controller->logger,
        resource   => $self->can('_resource') 
            ? $self->_resource 
            : $controller->resource // $resource;
    };
    #$app->logger->debug( "Creating new API Resource $class.");
    return bless $data, $class;
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