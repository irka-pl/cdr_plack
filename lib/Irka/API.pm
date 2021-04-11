#!/usr/bin/perl
package Irka::API;
use strict;
use warnings;

use parent qw(Class::Accessor);

use Plack::Request;
use Plack::Response;
use Data::Dumper;
use Try::Tiny;
use Log::Log4perl qw(get_logger :levels);
use HTTP::Status qw(:constants);
use Module::Runtime qw(is_module_name check_module_name require_module);

__PACKAGE__->mk_accessors( qw(request response) );

sub get_api_vendor{
    return split(/::/, __PACKAGE__)[0];
}

sub new{
    my ($class, $env) = @_;
    print Dumper \@_;
    my $data = {
        request  => Plack::Request->new( $env ),
        response => Plack::Response->new(),
    };
    return bless $data, $class;
}

sub to_app {
    my ( $self, $env ) = @_;
    my $req = $self->request();
    my $res = $self->response();
    if ( my $resource_api = $self->load_path_api( $req, $res ) ) {
        if( my $method = $resource_api->can( lc( $request->method ) ) ) {
            $method->();
        } else {
            $self->error_not_found();
        }
    }
    if(!$res->status){
        my $res = $req->new_response(200);
        $res->content_type('text/html');
        $res->body(Dumper($req));
    }
    $res->finalize;
}

sub load_path_api {
    my ($self) = @_;
    my @parts  = split($self->request->path_info);
    my $module = join('::', $self->get_api_vendor, 'API', @parts);
    my $object;
    try {
        $object = use_module($module)->new($self);
    }
    catch {
        $self->error_not_found;
    }
    return $object;
}

sub error_not_found {
    my ($self, $res) = @_;
    $res->status(HTTP_NOT_FOUND);
    $res->body('');
}
1;