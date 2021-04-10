use strict;
use warnings;
#use Plack::App::CGIBin;
use Plack::Builder;
use Data::Dumper;

use FindBin; 
use lib ($FindBin::Bin, "$FindBin::Bin/local/lib/perl5");
use Irka::API;
 
#my $app = Plack::App::CGIBin->new(root => "./bin")->to_app;
my $app = sub { 
    my($env) = @_;
    api->new()->to_app($env);
};

builder {
    mount "/" => $app;
};