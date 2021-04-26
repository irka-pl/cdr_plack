#!/usr/bin/perl
package GhostFW;
use strict;
use warnings;

use parent qw(Class::Accessor);

use Plack::Request;
use Plack::Response;

use Log::Log4perl qw(get_logger :levels);
#TODO: more general config, like any format loader?
use Config::General;
use HTTP::Request::Common;
use HTTP::Status qw(:constants);

use Data::Dumper;
use FindBin; 
use Try::Tiny;
use Module::Runtime qw(use_module);


__PACKAGE__->mk_ro_accessors( qw(logger) );

sub get_api_vendor{
    return (split(/::/, __PACKAGE__))[0];
}

#TODO::Config!
Log::Log4perl::init($FindBin::Bin.'/etc/logging.conf');
my $logger = Log::Log4perl->get_logger( get_api_vendor() );

sub new{
    my ($class) = @_;
    my $data = {
        logger => $logger,
        #config => Config::General->new('/etc/ghostfw.conf'),
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
        $self->logger->debug("Resource created.");
        my $method_name = lc( $request->method );
        #TODO: resolve conflick of the "get" method and Class::Accessor and remove this handle_method
        if ( $resource->handle_method($method_name) ) {
            $self->logger->debug("Method found: $method_name.");
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
    my @parts  = split(qr{/},$request->path_info);
    #TODO: instead of the ucfirst, make API module method "resource" and scan them on the start
    # as some resources can be two and more words concatenated and named using Camel style
    my $module = join('::',
        $self->get_api_vendor,
        #TODO: Config
        'API',
        ( $parts[1] 
            ? ( 'Resources', ucfirst($parts[2]) ) 
            : ()
        )
    );
    try {
        $self->logger->debug("Load module '$module'.");
        $object = use_module($module)->new($self, $request, $response);
    } catch {
        $self->logger->error("Failed to load module '$module': $_;");
        $self->error_not_found($response);
    };
    return $object;
}

sub model {
    my ($self, $model_name, $controller) = @_;
    my $object;
    #TODO: Config
    my $module = join('::', $self->get_api_vendor, 'Model', $model_name);
    $self->logger->debug("controller '$controller'.");
    try {
        $self->logger->debug("Load module '$module'.");
        $object = use_module($module)->new($controller);
    } catch {
        $self->logger->error("Failed to load module '$module' => use dafault;");
        #TODO: Later it should be dedicated module Default.
        $module = join('::', $self->get_api_vendor, 'Model', 'Base');
        $self->logger->error("Attempt to load module '$module';");
        $object = use_module($module)->new($controller);
    };
    return $object;
}

sub error_not_found {
    my ($self, $response) = @_;
    $response->status(HTTP_NOT_FOUND);
    $response->body('');
}
1;