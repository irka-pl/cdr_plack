#!/usr/bin/perl
package Irka::API;
use strict;
use warnings;

use Plack::Request;
use Plack::Response;

use Data::Dumper;

use Module::Runtime qw(is_module_name check_module_name require_module);

sub new{
    my ($class, $env) = @_;
    print Dumper \@_;
    my $data = {};
    return bless $data, $class;
}

sub to_app {
    my( $self, $env ) = @_;
    my $req = Plack::Request->new( $env );
    #my $res = $req->new_response(200);
    
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    $res->body(Dumper($req));
    $res->finalize;
}

1;