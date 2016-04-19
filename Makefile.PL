#!perl

BEGIN {
    @INC = grep { $_ ne '.' } @INC;
}

use strict;
use warnings;
use ExtUtils::MakeMaker;

unlink 'Config.h';
`$^X Config_h.PL`;
-e 'Config.h' or die("Config_h.PL didn't generate Config.h");

WriteMakefile(
    NAME         => "Config",
    VERSION_FROM => 'Config.pm',
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
