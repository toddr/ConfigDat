#!perl

use strict;
use warnings;

use B ();
use Config;

my ( $keys_start, $values_start );

open( my $fh, '>', 'Config.h' ) or die;

print {$fh} <<"HEADER";

struct  node_struct {
    unsigned short left, right;
    unsigned short value_pointer, key_pointer;
};

typedef struct node_struct KEY_NODE;

  
HEADER

print {$fh} sprintf( "#define NUMBER_OF_CONFIG_KEYS %d\n\n", scalar keys %Config );

# Make a balanced red/black B-Tree as a hash.
my $config_keys = scalar keys %Config;
my ($b_tree) = make_tree( [ sort keys %Config ], 0 );

# Figure out the size of each value so we can calculate jumps in the keys section.
my %values_position;
{
    no warnings 'uninitialized';    #undef can't be a key. that's ok we don't need to write out undef into the values section.
    %values_position = reverse %Config;
}

my @values                = ( sort keys %values_position );
my $values_array_position = 1;

print {$fh} "static const char * values_list = \n";
print {$fh} qq{    "\\000"\n};
foreach my $str (@values) {
    $values_position{$str} = $values_array_position;
    print {$fh} sprintf( "    %s\n", B::cstring( $str . "\x00" ) );
    $values_array_position += length($str) + 1;
    $values_array_position > 2**16 and die;
}
print {$fh} ";\n\n";

my %keys_position;
my $keys_array_position = 0;
print {$fh} "static const char * keys_list = \n";
foreach my $str ( sort keys %Config ) {
    $keys_position{$str} = $keys_array_position;
    print {$fh} sprintf( "    %s\n", B::cstring( $str . "\x00" ) );
    $keys_array_position += length($str) + 1;
    $keys_array_position > 2**16 and die;
}
print {$fh} ";\n\n";

print {$fh} "static KEY_NODE node_list[NUMBER_OF_CONFIG_KEYS] = {\n";

generate_tree_as_array( $b_tree, );
print {$fh} "};\n\n";
exit;

sub make_tree {
    my $keys                = shift;
    my $designated_position = shift;

    my $len = scalar @$keys or die;    # We shouldn't be descending into a node with no keys.
    my $node = {};

    if ( $len == 1 ) {
        $node->{'here'}     = $keys->[0];
        $node->{'position'} = $designated_position;
        return ( $node, $designated_position + 1 );
    }

    # Find the left tree
    my $fork_size = int( $len / 2 );
    my @left_array = splice( @$keys, 0, $fork_size );

    my $next_position;
    ( $node->{'left'}, $next_position ) = make_tree( \@left_array, $designated_position + 1 );

    # Middle node.
    $node->{'here'}     = shift @$keys;
    $node->{'position'} = $designated_position;    # We need to use the original position.

    # Right tree
    ( $node->{'right'}, $next_position ) = make_tree( $keys, $next_position ) if (@$keys);

    return ( $node, $next_position );
}

# A record is comprised of the following information.
# pack('VVVV', $left_seek, $right_seek, $key_len, $value_seek) . "$key_name";

sub generate_tree_as_array {
    my ( $node, $array ) = @_;

    my $key        = $node->{'here'};
    my $keys_value = $Config{$key};

    print {$fh} sprintf(
        "  { %d, %d, %d, %d }, /* Key node for %s */\n",
        $node->{'left'}     ? $node->{'left'}->{'position'}  : 0,
        $node->{'right'}    ? $node->{'right'}->{'position'} : 0,
        defined $keys_value ? $values_position{$keys_value}  : 0,
        $keys_position{$key}, $key
    );

    generate_tree_as_array( $node->{'left'},  $array ) if ( $node->{'left'} );
    generate_tree_as_array( $node->{'right'}, $array ) if ( $node->{'right'} );
}
