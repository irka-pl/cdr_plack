package GhostFW::DB;
use strict;
use warnings;

use parent qw(Class::Accessor);

use DBI;
use Ref::Util qw(is_arrayref is_hashref);

__PACKAGE__->mk_accessors( qw(dbh logger) );

# takes:
#  hashref $params that may contain:
#   - logger - global logger object
sub new {
    my ($class, $params) = @_;
    my $dbh = DBI->connect('dbi:SQLite:cdr', undef, undef, {
        AutoCommit => 1,
        RaiseError => 1,
        sqlite_see_if_its_a_number => 1,
    });
    $params = {} unless is_hashref($params);
    my $data = {
        dbh    => $dbh,
        %$params,
    };
    return bless $data, $class;
}

sub query {
    my ($self, $sql, $bind_values, $attrs) = @_;
    ($bind_values, $attrs) = $self->_prepare_args($bind_values, $attrs);
    return $self->dbh->do($sql, %$attrs, @$bind_values);
}

sub get_list {
    my ($self, $sql, $bind_values, $attrs) = @_;
    ($bind_values, $attrs) = $self->_prepare_args($bind_values, $attrs);
    $attrs->{Slice} = {};
    return $self->dbh->selectall_arrayref($sql, $attrs, @$bind_values);
}

#---- private methods

sub _prepare_args {
    my ($self, $bind_values, $attrs) = @_;
    $bind_values = [] unless is_arrayref($bind_values);
    $attrs = {} unless is_hashref($attrs);
    return ($bind_values, $attrs);
}

1;