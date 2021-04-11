#!/usr/bin/perl
package GhostFW;
use strict;
use warnings;

use parent qw(Class::Accessor);

use Plack::Request;
use Plack::Response;
use Data::Dumper;
use Try::Tiny;
use Log::Log4perl qw(get_logger :levels);
use HTTP::Status qw(:constants);
use FindBin; 
use Module::Runtime qw(is_module_name check_module_name require_module);

__PACKAGE__->mk_accessors( qw(logger) );

sub get_api_vendor{
    return (split(/::/, __PACKAGE__))[0];
}

Log::Log4perl::init($FindBin::Bin.'/etc/logging.conf');
my $logger = Log::Log4perl->get_logger( get_api_vendor() );

sub new{
    my ($class) = @_;
    my $data = {
        logger   => $logger,
    };
    $logger->debug(Dumper(\@_));
    return bless $data, $class;
}

sub to_app {
    my ( $self, $env ) = @_;
    my $request  = Plack::Request->new( $env );
    my $response = Plack::Response->new();
    #my $req = $self->request();
    #my $res = $self->response();
    if ( my $resource = $self->load_path_api( $request, $response ) ) {
        my $method = $resource->can( lc( $request->method ) );
        if ( $method ) {
            $method->();
        } else {
            $self->error_not_found();
        }
    }
    if(!$response->status){
        $response->status(200);
        $response->content_type('text/html');
        $response->body(Dumper($request));
    }
    $response->finalize;
}

sub load_path_api {
    my ($self, $request, $response) = @_;
    my $object;
    my @parts  = split($request->path_info);
    #TODO: instead of the ucfirst, make API module config parameter resource and scan on the start
    # as some resources can be two and more words concatenated
    my $module = join('::',
        $self->get_api_vendor,
        'API',
        ( $parts[1] 
            ? ( 'Resources', ucfirst($parts[1]) ) 
            : ()
        )
    );
    try {
        $object = use_module($module)->new($self);
    }
    catch {
        $self->error_not_found;
    }
    return $object;
}

sub error_not_found {
    my ($self, $response) = @_;
    $response->status(HTTP_NOT_FOUND);
    $response->body('');
}
1;