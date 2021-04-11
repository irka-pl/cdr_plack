package Irka::API::Base;
use strict;
use warnings;

use parent qw(Class::Accessor);


__PACKAGE__->mk_accessors( qw(api sb) );

sub new{
    my ($class, $api) = @_;
    my $db = Irka::DB->new();
    my $data = {
        api => $api,
        db  => $db,
    };
    return bless $data, $class;
}

1;