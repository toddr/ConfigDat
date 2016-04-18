# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.

# for a description of the variables, please have a look at the
# Glossary file, as written in the Porting folder, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package Config;

#use strict;
#use warnings;
our %Config;
our $VERSION = "5.022001";

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

our $fh;

sub fh {
    return $fh if ($fh);
    open( $fh, '<', 'config.dat' ) or die "Can't read config.dat: $!";
    return $fh;
}

my $key_count    = 0;
my $key_position = 0;

sub FIRSTKEY {
    my $self = shift;
    $fh or fh();

    $key_position = 0;
    if ( !$key_count ) {
        seek( $fh, 0, 0 );

        my $buffer;
        read( $fh, $buffer, 4 );
        $key_count = unpack( 'N', $buffer );
    }
    else {
        seek( $fh, 4, 0 );    # Skip the keys bytes count and start at the beginning of the btree.
    }

    return $self->NEXTKEY();
}

sub SCALAR { return 1 }

sub NEXTKEY {
    my $self = shift;
    $fh or fh();

    return undef if ( $key_position >= $key_count );

    my $buffer;
    my $got = read( $fh, $buffer, 16 );
    my ( $left_seek, $right_seek, $key_len, $value_seek ) = unpack( 'NNNN', $buffer );

    read( $fh, $buffer, $key_len );
    my ($key) = unpack( 'Z*', $buffer );

    $key_position++;
    return $key;

    #seek($fh, 1, $key_len);

}

# A key record is comprised of the following information.
# pack('NNNNZ*', $left_seek, $right_seek, $key_len, $value_seek, $key_name);

sub FETCH {
    my ( $self, $key ) = @_;

    return if ( !defined $key );    # undef keys aren't legal.

    $fh or fh();
    seek( $fh, 4, 0 );              # Skip the keys bytes count and start at the beginning of the btree.
    my $key = find_key( $fh, $key );
    undef $fh;
}

# Walks the btree and finds the key.
sub find_key {
    my ( $fh, $key ) = @_;

    my $buffer;
    my $got = read( $fh, $buffer, 16 );
    my ( $left_seek, $right_seek, $key_len, $value_seek ) = unpack( 'NNNN', $buffer );

    read( $fh, $buffer, $key_len - 1 );

    if ( $buffer eq $key ) {
        $value_seek or return undef;
        seek( $fh, $value_seek, 0 );

        read( $fh, $buffer, 4 );
        my ($value_len) = unpack( 'N', $buffer );

        read( $fh, $buffer, $value_len );
        return unpack( 'Z*', $buffer );
    }

    if ( $buffer gt $key ) {
        $left_seek or return undef;
        seek( $fh, $left_seek, 0 );
        return find_key( $fh, $key );
    }

    $right_seek or return undef;
    seek( $fh, $right_seek, 0 );
    return find_key( $fh, $key );
}

sub TIEHASH {
    bless $_[1], $_[0];
}

sub DESTROY { }

sub AUTOLOAD {
    require 'Config_heavy.pl';
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}

# tie returns the object, so the value returned to require will be true.
tie %Config, 'Config', {
    archlibexp       => '/usr/local/cpanel/3rdparty/perl/522/lib64/perl5/5.22.1/x86_64-linux-64int',
    archname         => 'x86_64-linux-64int',
    cc               => '/usr/bin/gcc',
    d_readlink       => 'define',
    d_symlink        => 'define',
    dlext            => 'so',
    dlsrc            => 'dl_dlopen.xs',
    dont_use_nlink   => undef,
    exe_ext          => '',
    inc_version_list => ' ',
    intsize          => '4',
    ldlibpthname     => 'LD_LIBRARY_PATH',
    libpth           => '/usr/local/cpanel/3rdparty/perl/522/lib64 /usr/local/cpanel/3rdparty/lib64 /usr/local/lib64 /usr/local/lib /lib64 /usr/lib64 /usr/local/lib /usr/lib /lib/../lib64 /usr/lib/../lib64 /lib',
    osname           => 'linux',
    osvers           => '3.10.0-123.20.1.el7.x86_64',
    path_sep         => ':',
    privlibexp       => '/usr/local/cpanel/3rdparty/perl/522/lib64/perl5/5.22.1',
    scriptdir        => '/usr/local/cpanel/3rdparty/perl/522/bin',
    sitearchexp      => '/opt/cpanel/perl5/522/site_lib/x86_64-linux-64int',
    sitelibexp       => '/opt/cpanel/perl5/522/site_lib',
    so               => 'so',
    useithreads      => undef,
    usevendorprefix  => 'define',
    version          => '5.22.1',
};
