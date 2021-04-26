package GhostFW::Model::DB::Base;
use strict;
use warnings;


use parent qw(Class::Accessor);

use Try::Tiny;
use Module::Runtime qw(use_module);
use GhostFW::DB;
use GhostFW::Utils qw(resource_from_classname);
use FindBin;
use Data::Dumper;
use feature 'state';

__PACKAGE__->mk_accessors( qw(db logger table) );

#TODO: Config


sub new {
    my ($class, $model) = @_;
    #TODO: config
    state $db = GhostFW::DB->new({
        dbfile          => "$FindBin::Bin/data/store/db.sql",
        create_sql_file => "$FindBin::Bin/data/init/001.sql",
        logger          => $model->logger,
    });
    my $data = {
        model  => $model,
        db     => $db,
        #shortcuts
        logger => $model->logger,
        #TODO: define key field from the DB structure, or config
        key    => 'id',
    };
    my $self = bless $data, $class;
    my $table = $self->can('_table') 
            ? $self->_table 
            : lc($model->resource // resource_from_classname($class));
    $self->table($table);
    $model->logger->debug( "Creating new Resource Model DB $class.");
    return $self;
}

#parameter $where_in should contain AND | OR operator at the end, if it is not empty
#binds parameter is mandatory
sub get_where ($$$;$) {
    my($self, $params, $binds, $where_in) = @_;
    $params //= {};
    my @where;
    #interesting fact about while - hash should be reset after each "each" loop, e.g. with keys call.
    foreach  my $field (keys %{$params->{filter_eq}}) {
        #TODO: check injection in $field
        push @where, qq{$field = ?};
        push @$binds, $params->{filter_eq}->{$field};
    }
    $where_in //= @where ? ' WHERE ' : '';
    $where_in .= join(' AND ', @where);
    #binds are changed implicitly 
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
    my $binds = [];
    my $sql = 'select * from '.$self->table.$self->get_where($params, $binds);
    return $self->db()->get_list($sql, $binds);
}

sub get_item{
    my($self, $params) = @_;
    my $item = $self->get_item($params);
    #TODO: throw warning if we have more than one row
    return $item;
}

sub get_item_by_id{
    my($self, $id) = @_;
    my $list = $self->db()->get_list('select * from '.$self->table.' WHERE '.$self->key.' = ? ', [$id]);
    #TODO: throw warning if we have more than one row
    return $list->[0];
}

sub update_item{
    my($self, $id, $data) = @_;
    my $sql = 'update '.$self->table.' set ';
    my $binds = [];
    foreach my $field (keys %$data) {
        $sql .= $field.' = ? ';
        push @$binds, $data->{$field};
    }
    $sql .= ' WHERE '.$self->key.' = ? ';
    push @$binds, $id;
    return $self->db()->query($sql, $binds);
}

sub delete_item_by_id{
    my($self, $id) = @_;
    my $sql = 'delete from '.$self->table.' where '.$self->key. ' = ?';
    my $binds = [$id];
    return $self->db()->query($sql, $binds);
}

sub delete_items_by_ids{
    my($self, $ids) = @_;
    my $sql = 'delete from '.$self->table.' where '
        .$self->key. ' in ('.join('',('?') x scalar @$ids).')';
    return $self->db()->query($sql, $ids);
}

sub create_item{
    my($self, $data) = @_;
    my @fields = keys %$data;
    my $sql = 'insert into '.$self->table.'('.join(',', @fields).') values '
        .' ('.join(',', ('?') x scalar @fields).')';
    my $binds = [@{$data}{@fields}];
    $self->logger->debug(Dumper([$data, $sql, $binds]));
    return $self->db()->query($sql, $binds);
}

sub create_items{
    my($self, $fields, $data) = @_;
    my $bucket_size = 1000;
    my $sql_start = 'insert into '.$self->table.'('.join(',', @$fields).') values ';
    my $sql_values = '('.join(',', ('?') x scalar @$fields).')';
    # if we want to send all-in-one
    #    . join(',', ('('.join(',', ('?') x scalar @$fields).')') x scalar @$data );
    my $i = 0;
    do {
        my $rows = ( $i + $bucket_size ) > @$data ? @$data - $i : $bucket_size;
        my $data_end_index = $i + $rows;
        my $sql = $sql_start . join(',', ($sql_values) x $rows );
        my $binds = [map {@{$_}} @$data[$i..$data_end_index]];
        $self->db()->query($sql, $binds);
    } while ($i < @$data);
    #TODO: catch error and rollback transaction. Wrap ALL queries in one transaction.
}


1;