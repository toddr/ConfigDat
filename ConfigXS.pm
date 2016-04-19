# This file was created by configpm when Perl was built. Any changes
# made to this file will be lost the next time perl is built.

# for a description of the variables, please have a look at the
# Glossary file, as written in the Porting folder, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package ConfigXS;

use strict;
use warnings;
our %Config;
our $VERSION = "5.022001";
our $AUTOLOAD;

use XSLoader;
XSLoader::load 'ConfigXS', $VERSION;

# Need to stub all the functions to make code such as print Config::config_sh
# keep working


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

# tie returns the object, so the value returned to require will be true.
tie %Config, 'ConfigXS', {};
