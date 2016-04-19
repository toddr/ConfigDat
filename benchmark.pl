#!perl

# enable hires wallclock timing if possible
use Benchmark ':hireswallclock';

use Config ();
use ConfigXS ();


#my @keys = keys %Config::Config;
#my @crap = values %Config::Config;

sub PP {
#    foreach my $key (@keys) { print "$key" if($Config::Config{$key} eq 'bdhndfjfjf') }
    foreach my $key (sort keys %Config::Config) { print "$key" if($Config::Config{$key} eq 'bdhndfjfjf') }
#    print "" foreach keys %Config::Config;
}

sub XS {
#    foreach my $key (@keys ) { print "$key" if($ConfigXS::Config{$key} eq 'bdhndfjfjf') }
    foreach my $key (sort keys %ConfigXS::Config ) { print "$key" if($ConfigXS::Config{$key} eq 'bdhndfjfjf') }
#    print "" foreach keys %ConfigXS::Config;
}

Benchmark::cmpthese( 300, {
    'PP' => \&PP,
    'XS' => \&XS,
});