#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Perfect",
    VERSION_FROM => 'Perfect.pm',
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
