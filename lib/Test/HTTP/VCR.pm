package Test::HTTP::VCR;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Carp qw(croak);

use constant DEFAULT_HTTPCLIENT => 'HTTP::Tiny';

=head1 NAME

Test::HTTP::VCR - A recorder for HTTP requests

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Test::HTTP::VCR;
    use HTTP::Tiny;

    my $httpclient = HTTP::Tiny->new;
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

=head1 DESCRIPTION

A tool to record and playback your HTTP interactions. This is especially useful for
testing web APIs.

Inspired by the Ruby library, VCR (https://github.com/vcr/vcr)

NOTE: This is alpha-level software. Please see also L<Test::VCR::LWP|https://metacpan.org/pod/Test::VCR::LWP>.

=cut

=head1 Class Methods

=head2 Test::HTTP::VCR->new($filename, [$opts])

Returns a Test::HTTP::VCR object. Throws error when $filename
is not passed in as the first argument.

=over 4

=item $filename specifies the file path to store the captured responses.

=item $opts is optional. It should be a hash reference if used. It could contain an optional key
'HTTPCLIENT' to specify the http client that needs its HTTP responses captured. Currently only Furl, HTTP::Tiny and LWP::UserAgent have been tested.

=back

=cut

sub new {
    my ($class, $tape, $opts) = @_;

    $tape or croak "Must pass in a filename";

    my $self = $opts;
    $self ||= {};

    bless $self, $class;

    $self->{tape} = $tape;
    $self->{HTTPCLIENT} ||= DEFAULT_HTTPCLIENT;

    # The 'request' method
    my $request_func;

    $self->{request_func} = $request_func = $self->{HTTPCLIENT} . '::request';

    # Saving the original implementation
    $self->{ori_request_func} = \&$request_func;

    return $self;
}

=head1 Instance Methods

=head2 record($code)

Returns 1. Records HTTP responses when HTTP requests are done using the 'HTTPCLIENT'
set in I<new> or 'HTTP::Tiny' if 'HTTPCLIENT' is not set.

=over 4

=item $code is a code reference to a function where the HTTP requests would have their responses captured.

=back

=cut

sub record {
    my ($self, $code) = @_;

    my @responses;

    # This implementation stores the responses returned by
    # the original implementation
    $self->_run_request_func(sub {
            my $res = $self->{ori_request_func}->(@_);
            push @responses, $res;
            return $res;
        },
        $code
    );

    # Store the responses to tape
    my $tape = $self->{tape};
    open my $fh, '>', $tape or die "Cannot open $tape for writing: $!";
    local $Data::Dumper::Purity = 1;
    print $fh Dumper(\@responses);
    close $fh;

    1;
}

=head2 play($code)

Returns 1. Replays HTTP responses from $filename set in I<new> when HTTP requests are done
using the 'HTTPCLIENT' (also set in I<new>) or 'HTTP::Tiny' if 'HTTPCLIENT' is not set.

=over 4

=item $code is a code reference to a function where the HTTP requests would have the captured responses returned.

=back

=cut

sub play {
    my ($self, $code) = @_;

    my $tape = $self->{tape};

    # Restore responses from tape
    open my $fh, $tape or die "Cannot open $tape for reading: $!";
    local $/;
    my $file_content = <$fh>;
    close $fh;

    our $VAR1;
    eval $file_content;
    my @responses = @$VAR1;

    # Return stored responses
    $self->_run_request_func(sub {
            my $res = shift @responses;
            return $res;
        }, $code);

    1;
}

sub _run_request_func {
    my ($self, $code, $user_code) = @_;
    no strict "refs";
    no warnings "redefine";

    my $request_func = $self->{request_func};

    # Define a local implementation of the 'request' method
    local *$request_func = $code;

    $user_code->();
}

=head1 TODO

=over 4

=item Spin up a simple HTTP server for testing

=item Test other HTTP methods (POST, PUT, DELETE)

=back

=cut

=head1 SEE ALSO

L<Test::VCR::LWP|https://metacpan.org/pod/Test::VCR::LWP>

=cut

=head1 AUTHOR

skliew, C<< <skliew at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTP::VCR

=head1 LICENSE AND COPYRIGHT

Artistic License 2.0. See LICENSE for details.

=cut

1; # End of Test::HTTP::VCR
