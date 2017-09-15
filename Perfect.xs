
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

#define MAX_HASH_SEED 0xFFFFFFFF

MODULE = Perfect       PACKAGE = Perfect

PROTOTYPES: DISABLE

IV
get_perfect_minimal_hash_from_array(array_ref)
    SV *array_ref
    
    PREINIT:
        AV *av_array;
        int key_count;
        int hash_for_key;
        SV **svp;
        SV *sv;
        char *str;
        unsigned int hash_got;
        unsigned int hashes_got[10000];
        unsigned int best_hash_found = 0;
        unsigned int minimal_hash_found;
        unsigned int mask;
        
        //for loops
        unsigned int key_num;
        unsigned int hash_to_try;
        unsigned int hashes_so_far;
        
    CODE:
        if (SvROK(array_ref) && SvTYPE(SvRV(array_ref)) == SVt_PVAV)
            av_array = (AV*)SvRV(array_ref);
        else
            croak("Array Ref not passed to get_perfect_minimal_hash.");
        
        key_count = AvFILLp(av_array);
        if(!key_count) croak("Passed Array Ref is empty!");
        
        // The mask needs to be a power of 2 > the key count -1;
        for(mask = 2; mask < key_count; mask *= 2) {
            ;
        }
        mask *= 2; // Make the mask twice as big as we need so we can see how little we need.
        minimal_hash_found = mask;
        mask--;
        
        // Validate the array is not empty.
        svp = AvARRAY(av_array);
        if(!svp) croak("Passed Array Ref is empty!");
        
        // Validate the array members are valid non-zero size PVs.
        for(key_num = 0; key_num < key_count; key_num++) {
            sv = svp[key_num];
            if(!sv)        croak("Key entry in passed array is null");
            if(!SvPVX(sv))  croak("No PV found for key in array");
            if(!SvCUR(sv)) croak("No length found for key in array");
        }
        
        // find the best hash.
        for(hash_to_try = 0; hash_to_try < MAX_HASH_SEED; hash_to_try++) {
            for(key_num = 0; key_num < key_count; key_num++) {
                sv = svp[key_count];
                PERL_HASH_WITH_STATE(hash_to_try, hash_got, SvPVX_const(sv), SvCUR(sv));
                hash_got = hash_got | mask;
                
                // We already found something better.
                if(hash_got >= minimal_hash_found) break;
                
                hashes_got[key_num] = hash_got;
                
                // Have we seen this hash already?
                for(hashes_so_far = 0; hashes_so_far < key_num; hashes_so_far++) {
                    if(hashes_got[hashes_so_far] == hash_got) { // We already found this hash. not perfect. try a new hash.
                        goto TRYTHENEXTHASH;
                    }
                }
            }
            
            // What was our highest hash for this hash number?
            for(minimal_hash_found = hashes_got[0], key_num = 1; key_num < key_count ; key_num++) {
                if(minimal_hash_found < hashes_got[key_num]) minimal_hash_found = hashes_got[key_num];
            }
            
            TRYTHENEXTHASH: 1;
        }
        
        XSRETURN_IV(minimal_hash_found);
        
    
    
        