use warnings;
use strict;

use Net::Domain qw(hostfqdn);
use LWP::UserAgent;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

#multipart/form-data
my $ua = LWP::UserAgent->new;
#my $uri = 'http://192.168.56.101:3001/api/cdr';
my $uri = 'http://127.0.0.1:3001/api/cdr';

diag("Test GET");
{
    my $req = HTTP::Request->new('GET', $uri.'/?filter_period_start_date_time=2016-01-01T00:00:00&filter_period_start_date_time=2017-01-01T00:00:00&filter_like_reference=C5DA97%');
    my $request_time = time;
    my $res = $ua->request($req);
    #print Dumper($res);
    $request_time = time() - $request_time;
    print "time=$request_time;";
}

diag("Test POST");
{
    my $req = POST $uri,
        #Content_Type => 'multipart/form-data',
        Content_Type => 'form-data',
        Content => {
            #file => ["$FindBin::Bin/data/techtest_cdr_small.csv"]
            file => ["$FindBin::Bin/data/techtest_cdr.csv"]
        };
    my $request_time = time;
    my $res = $ua->request($req);
    $request_time = time() - $request_time;
    print "time=$request_time;";
    #print Dumper($res);
}