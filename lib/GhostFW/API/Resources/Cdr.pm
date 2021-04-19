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

sub GET {
    my($self) = @_;
    my $data = $self->model()->get_list;
    $self->response->status(200);
}

1;