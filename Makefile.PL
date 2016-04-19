#!perl

BEGIN {
    @INC = grep { $_ ne '.' } @INC;
}

use strict;
use warnings;
use ExtUtils::MakeMaker;

unlink 'ConfigXS.h';
`$^X makeConfigXS.h`;
-e 'ConfigXS.h' or die("makeConfigXS.h didn't generate ConfigXS.h");

WriteMakefile(
    NAME         => "ConfigXS",
    VERSION_FROM => 'ConfigXS.pm',
    'dist'       => {
        COMPRESS     => 'gzip -9f',
        SUFFIX       => 'gz',
        DIST_DEFAULT => 'all tardist',
    },
    LICENSE   => 'perl',
    PREREQ_PM => {
        Config => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/toddr/ConfigDat',
        },
    },
);
