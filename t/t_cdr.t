use warnings;
use strict;

use Net::Domain qw(hostfqdn);
use LWP::UserAgent;
use Test::More;
use HTTP::Request;
use LWP::UserAgent;
#multipart/form-data
my $ua = LWP::UserAgent->new;
my $uri = 'http://192.168.56.101:3001/api/cdr';

diag("Test GET");
my $req = HTTP::Request->new('GET', $uri);
my $request_time = time;
my $res = $ua->request($req);
$request_time = time() - $request_time;

diag("Test POST");
my $req = POST $uri,
    Content_Type => 'multipart/form-data',
    Content => {
        file => 
    };
