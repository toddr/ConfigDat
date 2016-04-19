#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "stdio.h"
#include "string.h"

#include "ConfigXS.h"

#ifdef __cplusplus
}
#endif


MODULE = ConfigXS       PACKAGE = ConfigXS

PROTOTYPES: DISABLE

SV *
find_key (key)
    const char * key;
    
    CODE:
    const char * value;
    int cmp_result;
    int iterations = 0;
    short node_number = 0;
    
    while(iterations++ < 20) {
        cmp_result = strcmp(key,  keys_list + node_list[node_number].key_pointer);
        if(cmp_result == 0) {
            if (node_list[node_number].value_pointer == 0)
                XSRETURN_UNDEF;

            value = values_list + node_list[node_number].value_pointer;
            XSRETURN_PVN(value, strlen(value));
        }
    
        if(cmp_result < 0 ) {
            node_number = node_list[node_number].left;
        }
        else {
            node_number = node_list[node_number].right;
        }
    
        if(node_number == 0)
            XSRETURN_UNDEF;
    }

SV *
get_static_key_count ()
    CODE:
    XSRETURN_IV(NUMBER_OF_CONFIG_KEYS);

SV *
get_key_number (node_number)
    short node_number;
    
    CODE:
    const char * key = keys_list + node_list[node_number].key_pointer;
    XSRETURN_PVN(key, strlen(key));
