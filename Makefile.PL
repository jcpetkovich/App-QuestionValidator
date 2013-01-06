use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::QuestionValidator',
    AUTHOR           => q{Jean-Christophe Petkovich <jcpetkovich@gmail.com>},
    VERSION_FROM     => 'lib/App/QuestionValidator.pm',
    ABSTRACT_FROM    => 'lib/App/QuestionValidator.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => { },
    EXE_FILES        => [ 'question-validator' ],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Text::CSV' => 1.15,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => {
        FILES => 'App-QuestionValidator-* *.log',
    },
);
