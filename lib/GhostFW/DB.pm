package GhostFW::DB;
use strict;
use warnings;

use parent qw(Class::Accessor);

use Data::Dumper;
use DBI;
use Ref::Util qw(is_arrayref is_hashref);
use File::Slurp qw(slurp);
use DateTime::Format::SQLite;

__PACKAGE__->mk_accessors( qw(dbh logger) );

# takes:
#  hashref $params that may contain:
#   - logger          - global logger object
#   - dbfile          - full path to the database 
#   - create_sql      - set of ddl sentences to run if parameter create is set or dbfile is set and is absent
#   - create_sql_file - file with set of ddl sentences to run if parameter create is set or dbfile is set and is absent

#TODO: think about this object creation place - we can keep it for different requests
#TODO: move sqlite specific, e.g. creation and connect to child module
#TODO: think about berkly db in this place - just for fun
sub new {
    my ($class, $params) = @_;
    $params = {} unless is_hashref($params);
    
    #TODO: separate db engine specific
    #sqlite specific
    my $dbh = DBI->connect(
        'dbi:SQLite'.($params->{dbfile} ? ':dbname='.$params->{dbfile} : ':memory'),
        undef,
        undef,
        {
            AutoCommit => 1,
            RaiseError => 1,
            sqlite_see_if_its_a_number => 1,
            #TODO: change default to 0
        }
    );
    #/sqlite specific
    #TODO: configure and pass it properly
    #TODO: get log4perl file from the (file?) appender?
    $dbh->trace(1, '/tmp/cdr.log');

    my $data = {
        dbh    => $dbh,
        %$params,
    };
    my $self = bless $data, $class;

    #sqlite specific
    $self->logger->debug("Check 'version' table existance.");
    if (!$self->get_item("SELECT name FROM sqlite_master WHERE type='table' AND name='version'") ) {
        $self->logger->debug("Create sqlite database. File: ".($params->{dbfile} // 'memory'));
        my $create_sql = delete $params->{create_sql};
        $self->logger->info("create sql: ".($create_sql // 'empty, will check file'));
        if(!$create_sql) {
            my $create_sql_file = delete $params->{create_sql_file};
            $self->logger->info("Try to read sql from the file: $create_sql_file");
            if( $create_sql_file && -e $create_sql_file ) {
                $self->logger->info("Read sql from the file: $create_sql_file");
                $create_sql = slurp($create_sql_file);
            }
        }
        # this is for convenience only, no strict requirements about defined database
        # so no die or throw there
        if($create_sql){
            $self->logger->info("run create sql: $create_sql;");
            $self->query($create_sql);
        }
        #TODO: check version again and create table here, if not exists
    }
    #/sqlite specific

    return $self;
}

sub query {
    my ($self, $sql, $bind_values, $attrs) = @_;
    ($bind_values, $attrs) = $self->_prepare_args($bind_values, $attrs);
    #$self->logger->debug(Dumper([$sql, $attrs, $bind_values]));
    my $result = $self->dbh->do($sql, $attrs, @$bind_values);
    $self->logger->debug("do result: $result");
    return $result;
}

sub get_list {
    my ($self, $sql, $bind_values, $attrs) = @_;
    ($bind_values, $attrs) = $self->_prepare_args($bind_values, $attrs);
    $attrs->{Slice} = {};
    return $self->dbh->selectall_arrayref($sql, $attrs, @$bind_values);
}

sub get_item {
    my ($self, $sql, $bind_values, $attrs) = @_;
    ($bind_values, $attrs) = $self->_prepare_args($bind_values, $attrs);
    return $self->dbh->selectrow_hashref($sql, $attrs, @$bind_values);
}

#---- private methods

sub _prepare_args {
    my ($self, $bind_values, $attrs) = @_;
    $bind_values = [] unless is_arrayref($bind_values);
    #todo: separate to SQLite specific package
    foreach ( @$bind_values ) {
        if(ref $_ eq 'DateTime') {
            $_ = DateTime::Format::SQLite->format_datetime($_);
        }
    }
    $attrs = {} unless is_hashref($attrs);
    return ($bind_values, $attrs);
}

sub DESTROY {
    my ($self) = @_;
    $self->dbh->disconnect;
} 
1;