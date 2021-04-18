package GhostFW::Model::Base;

use parent qw(Class::Accessor);
use Try::Tiny;
use Module::Runtime qw(use_module);
use GhostFW::DB;
use GhostFW::Utils qw(resource_from_classname);

__PACKAGE__->mk_accessors( qw(dbh logger table) );


sub new {
    my ($class, $model) = @_;
    my $db = GhostFW::DB->new;
    #TODO: config
    my $table = $self->can('_table') 
            ? $self->_table 
            : $model->resource // resource_from_classname($class);
     my $data = {
        model  => $model,
        db     => $db,
        #shortcuts
        logger => $model->logger,
        table  => $table,
        #TODO: define key field from the DB structure, or config
        key     => 'id',
    };
    $app->logger->debug( "Creating new Resource Model DB $class.");
    return bless $data, $class;
}

#parameter $where_in should contain AND | OR operator at the end, if it is not empty
sub get_where{
    my($self, $params, $binds, $where_in) = @_;
    $params //= {};
    my @where;
    $binds // {};
    #interesting fact about while - hash should be reset after each "each" loop, e.g. with keys call.
    foreach  my $key (keys %{$params->{filter_eq}}) {
        #TODO: check injection in $key
        push @where, qq{$key = ?};
        push @binds, $params->{filter_eq}->{};
    }
    $where_in //= @where ? ' WHERE ' : '';
    $where_in .= join(' AND ', @where);
    return $where_in;
}

#params should be constructed on the Model level from the request parameters,
#based on internal Model knowledge what are possible filters, ordering, groupings etc
#for now can contain following keys: filter_eq
#examples of the others keys to implement: filter_in, filter_date, filter_date_period with possible infinite start, filter_in_like
#there is no sense to implement all possible logic, just the most often used variants.
#In more complex cases it is better to construct sql manually

sub get_list{
    my($self, $params) = @_;
    my $sql = 'select * from '.$self->table.$self->get_where($params);
    return $self->db()->get_list($sql, );
}

sub get_item{
    my($self, $params) = @_;
    return $self->db()->get_item('select * from '.$self->table.$self->get_where($params));
}

sub get_item_by_id{
    my($self, $id) = @_;
    return $self->db()->get_item('select * from '.$self->table.' WHERE '.$self->key.' = ? ');
}

sub update_item{
    my($self, $key, $data) = @_;
    my $sql = 
    return $self->db()->update_item('update '.$self->table.' set ');
}

sub delete_item{
    my($self, $key) = @_;
    return $self->db()->delete_item($key);
}

sub delete_items{
    my($self, $keys) = @_;
    return $self->db()->delete_items($keys);
}

sub create_item{
    my($self, $data) = @_;
    return $self->db()->create_item($data);
}

sub create_items{
    my($self, $data) = @_;
    return $self->db()->create_items($data);
}


1;