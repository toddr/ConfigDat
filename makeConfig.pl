#!perl

use strict;
use warnings;

use Config;

my ( $keys_start, $values_start );

# Make a balanced red/black B-Tree as a hash.
my $config_keys = scalar keys %Config;
my ($b_tree) = make_tree( [ sort keys %Config ], 0 );

# Figure out the size of each value so we can calculate jumps in the keys section.
my %values_position;
{
    no warnings 'uninitialized';    #undef can't be a key. that's ok we don't need to write out undef into the values section.
    %values_position = reverse %Config;
}
my $node_pointer_size = 4;          # We're going to use 32 bit ints (pack('N')) when we store file pointer info.

my $values_output = '';
my $val_pos       = 0;
foreach my $str ( sort keys %values_position ) {
    $values_position{$str} = $val_pos;
    $values_output .= pack( 'VZ*', length($str), $str );
    $val_pos += $node_pointer_size + length($str) + 1;    # n + length + null byte.
}

# Make the B-Tree a linear array like we're going to store it.
my $red_black_array = [];
generate_tree_as_array( $b_tree, $red_black_array );

# we wrote the left/right jumps as array positions now we need to figure out what the distances are by walking the $red_black_array

my @jump_positions;
my $key_distance_so_far = 0;                              # we store the keys count in the first 4 bytes of the file.
my $node_number         = 0;
foreach my $key (@$red_black_array) {
    $jump_positions[ $node_number++ ] = $key_distance_so_far;
    $key_distance_so_far += $node_pointer_size * 4 + length( $key->[4] ) + 1;    # pointers + key string + null.
}
my $values_start_pos = $key_distance_so_far + 4;                                 #values are stored after keys.

#Now let's walk the btree and store the jumps as pointers not array positions.

# A record is comprised of the following information.
# pack('VVVV', $left_seek, $right_seek, $key_len, $value_seek) . "$key_name";

my $btree_file = 'config.dat';
open( my $fh, '>', $btree_file ) or die;

print {$fh} pack( 'V', $config_keys );    # Store the key count for when people call keys.
foreach my $key (@$red_black_array) {
    $key->[0] = $jump_positions[ $key->[0] ] + 4 if $key->[0];
    $key->[1] = $jump_positions[ $key->[1] ] + 4 if $key->[1];
    if ( $key->[3] >= 0 ) {
        $key->[3] += $values_start_pos;
    }
    else {
        $key->[3] = 0;                    # undef.
    }

    print {$fh} pack( 'VVVVZ*', @$key );
}

print {$fh} $values_output;

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

    my $keys_value = $Config{ $node->{'here'} };
    push @$array, [
        $node->{'left'}  ? $node->{'left'}->{'position'}  : 0,
        $node->{'right'} ? $node->{'right'}->{'position'} : 0,
        length( $node->{'here'} ) + 1,
        defined $keys_value ? $values_position{$keys_value} : -1,    # -1 seek value means undef
        $node->{'here'},
    ];

    generate_tree_as_array( $node->{'left'},  $array ) if ( $node->{'left'} );
    generate_tree_as_array( $node->{'right'}, $array ) if ( $node->{'right'} );
}
