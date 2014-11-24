package t::TestRunner;
use strict;
use File::Temp qw/tempfile/;
use Test::More;
use Carp qw(croak);

BEGIN {
    use_ok('Test::HTTP::VCR') || print "Bail out!\n";
}

sub run {
    my $httpclientname = shift or croak "Must pass in httpclient";

  SKIP: {
        eval "require $httpclientname";
        skip "$httpclientname not installed", 2 if $@;

        my ( $fh, $tempfile ) = tempfile();

        my $vcr =
          Test::HTTP::VCR->new( $tempfile, { HTTPCLIENT => $httpclientname } );
        my $httpclient = $httpclientname->new;

        my $request_method_name = $httpclientname . '::request';
        my $request_method_code = \&$request_method_name;

        my $response;
        $vcr->record(
            sub {
                cmp_ok( $request_method_code, '!=', \&$request_method_name,
                    "$request_method_name is changed" );
                $response = $httpclient->get('https://google.com');
            }
        );

        cmp_ok( $request_method_code, '==', \&$request_method_name,
            "$request_method_name is restored" );

        my $response_playbank;
        $vcr->play(
            sub {
                $response_playbank = $httpclient->get('https://google.com');
            }
        );

        is_deeply( $response_playbank, $response,
            'Played response is correct' );

        unlink $tempfile;
    }
    done_testing();
}

1;
