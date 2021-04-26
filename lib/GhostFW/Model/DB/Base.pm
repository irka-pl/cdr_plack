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
use DateTime::Format::Flexible;
use DateTime;
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
    my($self, $filter, $binds, $where_in) = @_;
    $filter //= {};
    my (@wheres_and);
    foreach my $field (keys %{$filter}) {
        my @wheres_or;
        my $field_filter = $filter->{$field};
        #TODO: check injection in $field
        foreach my $op (keys %{$field_filter}) {
            my $values = $field_filter->{$op};
            if ($op eq 'eq') {
                if (@{$values} > 1) {
                    push @wheres_or, $field .' IN ('.join(',', ('?') x scalar @{$values}).')';
                } elsif (scalar @{$values} == 1) {
                    push @wheres_or, $field .' = '.$values->[0].'';
                }
                push @$binds, @{$values};            
            } elsif ($op eq 'like') {
                if ( @{$values} ) {
                    push @wheres_or, $field.' LIKE '.join(' OR '.$field.' LIKE ',('?') x scalar @{$values} );
                    push @$binds, @{$values};
                }
            } elsif ($op eq 'period') {
                if (scalar @{$values} == 2) {
                    my @values_dt = map {my $v = DateTime::Format::Flexible->parse_datetime($_); $v ? $v : () } @{$values};
                    if( scalar @values_dt == 2 ) {
                        push @wheres_or, $field.' BETWEEN ? AND ?';
                        push @$binds, sort { DateTime->compare_ignore_floating( $a, $b ) } @values_dt;
                    } else {
                        #todo - is_numeric, otherwise use string comparison
                    }
                }
            }
        }#we went through all operators for the field
        #now we can join collected @wheres_or by 'AND'
        if (@wheres_or) {
            push @wheres_and, '('.join(' OR ', @wheres_or).')';
        }
    }
    $where_in //= @wheres_and ? ' WHERE ' : '';
    $where_in .= join(' AND ', @wheres_and);
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
    my($self, $filter) = @_;
    my $binds = [];
    my $sql = 'select * from '.$self->table.$self->get_where($filter, $binds);
    $self->logger->debug("sql=$sql;".Dumper($filter));
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
    #$self->logger->debug(Dumper([$data, $sql, $binds]));
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