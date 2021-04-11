package GhostFW::API::Base;
use strict;
use warnings;

use parent qw(Class::Accessor);
use GhostFW::DB;

__PACKAGE__->mk_accessors( qw(app request response) );

sub new{
    my ($class, $app, $request, $response) = @_;
    my $db = GhostFW::DB->new();
    my $data = {
        app => $app,
        db  => $db,
    };
    return bless $data, $class;
}

sub options {
    
}

1;