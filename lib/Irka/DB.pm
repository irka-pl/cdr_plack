package Irka::DB;
use strict;
use warnings;

use parent qw(Class::Accessor);

use DBI;

my $dbh = DBI->connect('dbi:SQLite:cdr', undef, undef, {
  AutoCommit => 1,
  RaiseError => 1,
  sqlite_see_if_its_a_number => 1,
});

1;