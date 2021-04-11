package GhostFW::API::Cdr;
use strict;
use warnings;

use parent qw(GhostFW::API::Base);

sub post {
    my($self) = @_;
    $self->app->request
}

1;