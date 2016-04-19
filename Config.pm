# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.

# for a description of the variables, please have a look at the
# Glossary file, as written in the Porting folder, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package Config;

use strict;
use warnings;
our %Config;
our $VERSION = "5.022001";
our $AUTOLOAD;

BEGIN {
    if ( defined &DynaLoader::boot_DynaLoader ) {
        use XSLoader;
    }
    else {
        %Config:: = ();
        undef &{$_} for qw(import DESTROY AUTOLOAD);
        require 'Config_mini.pl';
    }
}

if ( $INC{'XSLoader.pm'} ) {
    XSLoader::load 'Config', $VERSION;
}

# Skip @Config::EXPORT because it only contains %Config, which we special
# case below as it's not a function. @Config::EXPORT won't change in the
# lifetime of Perl 5.
my %Export_Cache = (
    myconfig          => 1, config_sh             => 1, config_vars   => 1,
    config_re         => 1, compile_date          => 1, local_patches => 1,
    bincompat_options => 1, non_bincompat_options => 1,
    header_files      => 1
);

@Config::EXPORT    = qw(%Config);
@Config::EXPORT_OK = keys %Export_Cache;

# Need to stub all the functions to make code such as print Config::config_sh
# keep working

sub bincompat_options;
sub compile_date;
sub config_re;
sub config_sh;
sub config_vars;
sub header_files;
sub local_patches;
sub myconfig;
sub non_bincompat_options;

# Define our own import method to avoid pulling in the full Exporter:
sub import {
    shift;
    @_ = @Config::EXPORT unless @_;

    my @funcs = grep $_ ne '%Config', @_;
    my $export_Config = @funcs < @_ ? 1 : 0;

    no strict 'refs';
    my $callpkg = caller(0);
    foreach my $func (@funcs) {
        die qq{"$func" is not exported by the Config module\n}
          unless $Export_Cache{$func};
        *{ $callpkg . '::' . $func } = \&{$func};
    }

    *{"$callpkg\::Config"} = \%Config if $export_Config;
    return;
}

die "$0: Perl lib version (5.22.1) doesn't match executable '$^X' version ($])"
  unless $^V;

$^V eq 5.22.1
  or die sprintf "%s: Perl lib version (5.22.1) doesn't match executable '$^X' version (%vd)", $0, $^V;

my $key_count    = 0;
my $key_position = 0;

my %Config_local;

sub STORE {
    $Config_local{ $_[0] } = $_[1];
}

sub SCALAR { return 1 }

sub FIRSTKEY {
    my $self = shift;

    $key_count = get_static_key_count();

    $key_position = 0;
    return $self->NEXTKEY();
}

sub NEXTKEY {
    my $self = shift;

    return undef if ( $key_position + 1 > $key_count );    # 0  based array so add 1.

    return get_key_number( $key_position++ );
}

# A key record is comprised of the following information.
# pack('VVVVZ*', $left_seek, $right_seek, $key_len, $value_seek, $key_name);

sub FETCH {
    my ( $self, $key ) = @_;

    return undef if ( !defined $key );    # undef keys aren't legal.

    find_key($key);
}

sub TIEHASH {
    bless $_[1], $_[0];
}

sub DESTROY { }

sub AUTOLOAD {
    print "WANTED: $AUTOLOAD\n";
    require 'Config_heavy.pl';
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}

# tie returns the object, so the value returned to require will be true.
tie %Config, 'Config', {};
