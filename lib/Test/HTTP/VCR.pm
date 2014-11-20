package Test::HTTP::VCR;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Carp qw(croak);

use constant DEFAULT_HTTPCLIENT => 'Furl';

=head1 NAME

Test::HTTP::VCR - A recorder for HTTP requests

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

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

=head1 DESCRIPTION

A tool to record and playback your HTTP interactions. This is especially useful for
testing web APIs.

Inspired by the Ruby library, VCR (https://github.com/vcr/vcr)

NOTE: This is alpha-level software.

=cut

=head1 SUBROUTINES/METHODS

=head2 new

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

=head2 record

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

=head2 play

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

=head1 AUTHOR

skliew, C<< <skliew at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTP::VCR

=head1 LICENSE AND COPYRIGHT

Copyright 2014 skliew.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Test::HTTP::VCR
