package Perfect;

use strict;
use warnings;

our $VERSION = "5.026001";

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

if ($INC{'XSLoader.pm'}) {
    XSLoader::load 'Config', $VERSION ;
}

