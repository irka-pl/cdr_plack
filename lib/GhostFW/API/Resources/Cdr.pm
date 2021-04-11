package GhostFW::API::Resources::Cdr;
use strict;
use warnings;

use parent qw(GhostFW::API::Base);
use Data::Dumper;

sub POST {
    my($self) = @_;
    $self->logger->debug( Dumper(['uploads', $self->request->uploads ]));
    $self->response->status(200);
}

1;