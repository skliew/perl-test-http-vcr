package t::TestRunner;
use strict;
use File::Temp qw/tempfile/;
use Test::More;
use t::TestServer;
use Carp qw(croak);

use constant SERVER_PORT => 8080;
use constant SERVER_HOST => 'localhost';

my $server_root = 'http://' . SERVER_HOST . ':' . SERVER_PORT;

my $server_pid;

sub run_server {
    $server_pid = fork();
    if ($server_pid == -1) {
        return undef;
    } elsif ($server_pid) {
        # Parent
        # Do nothing;
        return $server_pid;
    } else {
        # Children
        TestServer->new->run(SERVER_PORT);
        exit(0);
    }
}


BEGIN {
    use_ok('Test::HTTP::VCR') || print "Bail out!\n";
    run_server() or warn "Failed to start server";
}

END {
    if ($server_pid) {
        print "Killing $server_pid\n";
        kill 'INT', $server_pid or warn "Failed to kill pid $server_pid";
    }
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
                $response = $httpclient->get($server_root);
            }
        );

        cmp_ok( $request_method_code, '==', \&$request_method_name,
            "$request_method_name is restored" );

        my $response_playback;
        $vcr->play(
            sub {
                $response_playback = $httpclient->get($server_root);
            }
        );

        is_deeply( $response_playback, $response,
            'Played response is correct' );

        unlink $tempfile;
    }
    done_testing();
}

1;
