use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::HTTP::VCR',
    AUTHOR           => q{skliew <skliew@gmail.com>},
    VERSION_FROM     => 'lib/Test/HTTP/VCR.pm',
    ABSTRACT_FROM    => 'lib/Test/HTTP/VCR.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    TEST_REQUIRES => {
        'HTTP::Server::Simple' => 0.44,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-HTTP-VCR-*' },
);
