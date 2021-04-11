package GhostFW::API::Base;
use strict;
use warnings;

use parent qw(Class::Accessor);
use GhostFW::DB;

__PACKAGE__->mk_ro_accessors( qw(app request response db logger) );

sub new{
    my ($class, $app, $request, $response) = @_;
    my $db = GhostFW::DB->new();
    my $data = {
        app      => $app,
        request  => $request,
        response => $response,
        db       => $db,
        #shortcut to app logger
        logger   => $app->logger,
    };
    print STDERR "Creating new API Resource".__PACKAGE__.";\n";
    return bless $data, $class;
}

sub post {
    my($self) = @_;
    $self->POST;
}

sub options {
    
}

1;