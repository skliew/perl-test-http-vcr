# NAME

Test::HTTP::VCR - A recorder for HTTP requests

# VERSION

Version 0.01

# SYNOPSIS

    use Test::HTTP::VCR;
    use Furl;

    my $httpclient = Furl->new;
    my $filename = 'mytape.tape';
    my $vcr = Test::HTTP::VCR->new($filename);
    my $response;
    $vcr->record(sub {
        $response = $httpclient->get('https://www.github.com');
    });
    
    # $another_response should be the same as $response;
    $vcr->play(sub {
        my $another_response = $httpclient->get('https://www.github.com');
    });

# DESCRIPTION

A tool to record and playback your HTTP interactions. This is especially useful for
testing web APIs.

Inspired by the Ruby library, VCR (https://github.com/vcr/vcr)

NOTE: This is alpha-level software.

# Class Methods

## Furl->new($filename, \[$opts\])

Returns a Test::HTTP::VCR object. Throws error when $filename
is not passed in as the first argument.

- $filename specifies the file path to store the captured responses.
- $opts is optional. It should be a hash reference if used. It could contain an optional key
'HTTPCLIENT' to specify the http client that needs its HTTP responses captured. Currently only 'Furl'
and 'LWP::UserAgent' are supported.

# Instance Methods

## record($code)

Returns 1. Records HTTP responses when HTTP requests are done using the 'HTTPCLIENT'
set in _new_ or 'Furl' if 'HTTPCLIENT' is not set.

## play($code)

Returns 1. Replays HTTP responses from $filename set in _new_ when HTTP requests are done
using the 'HTTPCLIENT' (also set in _new_) or 'Furl' if 'HTTPCLIENT' is not set.

# TODO

- Spin up a simple HTTP server for testing
- Test other HTTP methods (POST, PUT, DELETE)

# AUTHOR

skliew, `<skliew at gmail.com>`

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTP::VCR

# LICENSE AND COPYRIGHT

Artistic License 2.0. See LICENSE for details.