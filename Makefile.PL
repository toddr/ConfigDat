#!perl

BEGIN {
    @INC = grep { $_ ne '.' } @INC;
}

use strict;
use warnings;
use ExtUtils::MakeMaker;

unlink 'config.dat';
`$^X makeConfig.pl`;
-e 'config.dat' or die("makeConfig.pl didn't generate config.dat");

unlink 'Config.xs';
`$^X Config_xs.PL`;
-e 'Config.xs' or die("Config_xs.PL didn't generate Config.xs");

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
