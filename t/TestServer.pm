#!/usr/bin/env perl
package TestServer;
use strict;
use warnings;

use base qw(HTTP::Server::Simple::CGI);

my %dispatch = (
    '/redirect' => \&redirect_handler
);

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};

    if (defined($handler)) {
        return $handler->($cgi);
    } else {
        default_handler($cgi);
    }
}

sub default_handler {
    my ($cgi) = @_;
    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header('text/plain');
    print $ENV{REQUEST_METHOD}, "\n";
}

sub redirect_handler {
    my ($cgi) = @_;

    my $server_path = 'http://' . $ENV{HTTP_HOST} . '/';

    print "HTTP/1.0 301 Moved Permanently\r\n";
    print $cgi->redirect($server_path);
}

1;

