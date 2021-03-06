use 5.010;
use strict;
use warnings;
use lib 'lib/';

use Marpa::XS;
use MarpaX::Simple::Lexer;

my $grammar = Marpa::XS::Grammar->new( {
    actions => 'main',
    default_action => 'do_what_I_mean',
    start   => 'query',
    rules   => [
        {
            lhs => 'query', rhs => [qw(condition)],
            min => 1, separator => 'OP', proper => 1, keep => 1,
        },
        [ condition => [qw(word)] ],
        [ condition => [qw(quoted)] ],
        [ condition => [qw(OPEN-PAREN SPACE? query SPACE? CLOSE-PAREN)] ],
        [ condition => [qw(NOT condition)] ],

        [ 'SPACE?' => [] ],
        [ 'SPACE?' => [qw(SPACE)] ],
    ],
    lhs_terminals => 0,
});
$grammar->precompute;
my $recognizer = Marpa::XS::Recognizer->new( { grammar => $grammar } );

use Regexp::Common qw /delimited/;

my $lexer = MyLexer->new(
    recognizer => $recognizer,
    tokens => {
        word          => qr{\b\w+\b},
        'quoted'      => qr[$RE{delimited}{-delim=>qq{\'\"}}],
        OP            => qr{\s+(OR)\s+|\s+},
        NOT           => '!',
        'OPEN-PAREN'  => '(',
        'CLOSE-PAREN' => ')',
        'SPACE'       => qr{\s+()},
    },
    debug => 1,
);

$lexer->recognize(\*DATA);

use Data::Dumper;
print Dumper $recognizer->value;

sub do_what_I_mean {
    shift;
    my @children = grep defined && length, @_;
    return scalar @children > 1 ? \@children : shift @children;
}

package MyLexer;
use base 'MarpaX::Simple::Lexer';

sub grow_buffer {
    my $self = shift;
    my $rv = $self->SUPER::grow_buffer( @_ );
    ${ $self->buffer } =~ s/[\r\n]+//g;
    return $rv;
}

package main;
__DATA__
hello !world OR "he hehe hee" ( foo OR !boo )
