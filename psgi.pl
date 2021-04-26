use strict;
use warnings;
#use Plack::App::CGIBin;
use Plack::Builder;
use Data::Dumper;

use FindBin;
use lib ($FindBin::Bin, "$FindBin::Bin/lib", "$FindBin::Bin/local/lib/perl5");
use GhostFW;
 
#my $app = Plack::App::CGIBin->new(root => "./bin")->to_app;
my $app = sub { 
    my($env) = @_;
    GhostFW->new($FindBin::Bin)->to_app($env);
};

#I have seen discussion about dynamic mount
builder {
    mount "/" => $app;
};