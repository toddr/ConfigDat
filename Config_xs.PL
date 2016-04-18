#!perl

-e 'config.dat' or die("Please run makeConfig.pl to generate config.dat");

open( my $conf, '<', 'config.dat' ) or die;
my $contents = "const char *config_data = \n\"";

while ( !eof($conf) ) {
    my $char;
    read( $conf, $char, 1 ) or die;
    my $num = unpack( 'C', $char );
    if ( 0 && $num >= 32 and $num < 127 and $num != 92 and $num != 34 ) {
        $contents .= $char;
    }
    else {
        $contents .= sprintf( "\\x%02x", $num );
    }
    if ( tell($conf) % 50 == 0 ) {
        $contents .= qq{"\n"};
    }

}
$contents .= qq{";\n};
close $conf;

open( my $fh, '>', "Config.xs" ) or die;

print {$fh} <<"END_XS";

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "stdio.h"
#include "handy.h"
#include "string.h"

#ifdef __cplusplus
}
#endif

END_XS
print {$fh} $contents;
print {$fh} "\n\n";

print {$fh} <<"END_XS";
MODULE = Config       PACKAGE = Config

PROTOTYPES: DISABLE

#define DATA_INTEGER_SIZE 4
#define LSEEK 0
#define RSEEK      DATA_INTEGER_SIZE*1
#define KEYLEN     DATA_INTEGER_SIZE*2
#define VALUE_SEEK DATA_INTEGER_SIZE*3
#define KEY_STRING DATA_INTEGER_SIZE*4

SV *
find_key (key)
    const char * key
    
    CODE:
    /* Start after keys counter */    
    char *fp = (char *) config_data + 4;
    U32 key_value_len;
    U32 seek;
    U32 value_seek;
    int cmp_result;

    

    while(fp) {
        memcpy((char*) &key_value_len, fp + KEYLEN, 4);
        cmp_result = memcmp(key, fp + KEY_STRING, key_value_len);
        if(cmp_result == 0) {
            memcpy((char*) &value_seek, fp + VALUE_SEEK, 4);
            if(value_seek == 0)
                XSRETURN_UNDEF;
            memcpy((char*) &key_value_len, (char *)config_data + value_seek, 4);
            value_seek += 4;
            XSRETURN_PVN((char *)config_data + value_seek, key_value_len);
        }
    
    
        if(cmp_result > 0 ) {
            seek = RSEEK;
        }
        else {
            seek = LSEEK;
        }
        memcpy((char*) &seek, fp + seek, 4);
        fp = (char *)config_data + seek;
    
        if(fp == 0)
            XSRETURN_UNDEF;
    }

SV *
get_key_count ()
    CODE:
    U32 key_count;
    memcpy((char*) &key_count, config_data, 4);
    XSRETURN_IV(key_count);

SV *
get_key_number (number_wanted)
    U32 number_wanted;

    CODE:
    U32 key_value_len;
    int counter;

    char *fp = (char *) config_data + 4;
    for(counter=0; counter < number_wanted; counter++) {
        memcpy((char*) &key_value_len, fp + KEYLEN, 4);
        fp += KEY_STRING + key_value_len;
    }
    
    memcpy((char*) &key_value_len, fp + KEYLEN, 4);
    XSRETURN_PVN((char *)fp + KEY_STRING, key_value_len);


END_XS

