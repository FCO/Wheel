need Wheel::Kernel;
our constant WheelConvertible is export = Wheel::Kernel::WheelConvertible;
sub wheel($x) is export { Wheel::Kernel::wheel($x) }
sub reciprocal($x) is export { Wheel::Kernel::reciprocal($x) }
sub term:<⊥> is export { Wheel::Kernel::BOTTOM }
# A lexical operator replaces the native dispatcher; the kernel retains
# native arithmetic in its separate compilation scope.
my subset WheelOperand of Mu where { .defined && ($_ ~~ Numeric || $_ ~~ WheelConvertible) };

sub infix:<+>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('+', $a, $b) }

sub infix:<->(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('-', $a, $b) }

sub infix:<*>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('*', $a, $b) }

sub infix:</>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('/', $a, $b) }

sub infix:<**>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::power($a, $b) }

sub infix:<==>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('==', $a, $b) }

sub infix:<!=>(WheelOperand $a, WheelOperand $b) is export { Wheel::Kernel::calculate('!=', $a, $b) }

sub prefix:<+>(WheelOperand $a) is export { Wheel::Kernel::unary('+', $a) }

sub prefix:<->(WheelOperand $a) is export { Wheel::Kernel::unary('-', $a) }

=begin pod

=head1 NAME

Wheel - Lexically scoped arithmetic with infinity and bottom for Raku.

=head1 SYNOPSIS

=begin code
use Wheel;

say 1 / 0;       # Inf
say 0 / 0;       # ⊥
say -1 * Inf;    # Inf
say Inf * -1;    # Inf
say Inf / Inf;   # ⊥
say ⊥ + 42;      # ⊥
=end code

=head1 DESCRIPTION

Wheel exports arithmetic overloads and the term C<⊥> (bottom). It extends ordinary real arithmetic with a single infinity represented by C<Inf>, and a bottom value for indeterminate results.

Operations between Int, Rat and FatRat use exact rational arithmetic, returning Int for integral results and FatRat otherwise. Num and finite Complex arithmetic remain approximate. Both signs of infinity normalize to Inf; NaN (including a complex NaN component) normalizes to bottom. A complex value with an infinite component normalizes to Inf. These rules apply to operands and results.

=head1 SUPPORTED TYPES AND VALUES

The same operand types are accepted by C<wheel>, C<reciprocal>, the binary operators C<+>, C<->, C<*>, C</>, C<**>, C<==>, C<!=>, and the unary operators C<+> and C<->. Operands must be defined values.

=item C<Int>: arbitrary-precision integers, for example C<42> and C<-7>.

=item C<Rat>: rational numbers, including decimal literals such as C<1.5> and values constructed with C<Rat.new(1, 3)>.

=item C<FatRat>: arbitrary-precision rational numbers, for example C<FatRat.new(1, 3)>. Arithmetic between Int, Rat and FatRat is exact; integral results are returned as Int and nonintegral results as FatRat.

=item C<Num>: floating-point numbers, for example C<1e0> and C<2.5e0>. Finite arithmetic retains native rounding. C<Inf>, external C<-Inf> and C<NaN> are Num values, not separate types: infinities normalize to the single unsigned Inf and NaN normalizes to bottom.

=item C<Complex>: complex numbers, for example C<1+2i> or C<Complex.new(1, 2)>. Finite arithmetic uses native complex arithmetic. A NaN component makes the whole value bottom; otherwise an infinite component makes it Inf. Complex zero requires both components to be zero.

=item C<Bool>: C<False> and C<True> are accepted through their Int ancestry and act as zero and one in arithmetic.

=item C<IntStr>, C<RatStr>, C<NumStr> and C<ComplexStr>: Raku numeric allomorphs, such as those returned by C<val('42')> or C<val('1+2i')>, are accepted through their numeric ancestry. Their string representation is not used for calculation. An ordinary C<Str> is not a numeric allomorph and must be explicitly converted.

=item C<⊥>: the exported bottom singleton. Its implementation class is private; use the term rather than naming or constructing its class.

=item Types implementing C<WheelConvertible>: implement C<method wheel-value> to return a defined Int, Rat, FatRat, Num or Complex value without loss of information. Nested adapters and unsupported return values are rejected. The role is sufficient for entry to the operators; the adapter need not also implement Numeric.

Subclasses of supported numeric types are accepted through their ancestry, provided they retain compatible numeric behavior. Native machine values such as C<int> and C<num> are accepted when Raku boxes them into Int or Num at the call boundary. Abstract type objects such as C<Int>, undefined values, plain strings and other Numeric implementations without a supported ancestry or the adapter role are rejected.

Rat and FatRat values with denominator zero are also accepted: a nonzero numerator gives Inf, while a zero numerator gives bottom. The same normalization applies to values returned by adapters. Accepted types can be mixed in either operand position; mixed Num or Complex calculations retain the native floating-point limitations. Nonintegral powers also follow native arithmetic, as described under EXPONENTIATION.

=head1 IMPORTS AND LEXICAL SCOPE

Use either C<use Wheel;> or the symbolic alias C<use ::('⊙');>. Both names load the same implementation and export the same operators and bottom term. The symbolic name requires the indirect module-name syntax; C<use ⊙;> is not valid syntax.

Imports apply to the importing lexical scope and its nested scopes. They do not change enclosing or sibling scopes, or functions defined outside that scope. As with other Raku C<use> declarations, imports are resolved at compile time.

=begin code
{
    use ::('⊙');
    say -1 * Inf;       # Inf
    {
        say Inf * -1;   # Inf (inherited import)
    }
}
say -1 * Inf;           # -Inf (native arithmetic)
=end code

=head1 ARITHMETIC RULES

For the supported real numeric types, the special cases are:


=item Zero divided by zero gives C<⊥>.


=item A nonzero finite number divided by zero gives C<Inf>, regardless of sign.


=item C<Inf / 0> gives C<Inf>; C<Inf / Inf> gives C<⊥>.


=item C<Inf> divided by a finite number gives C<Inf>; a finite number divided by C<Inf> gives zero.


=item Zero multiplied by C<Inf>, in either order, gives C<⊥>.


=item A nonzero finite number multiplied by C<Inf>, in either order, gives C<Inf>, regardless of sign.


=item C<Inf * Inf> gives C<Inf>; C<Inf + Inf> and C<Inf - Inf> give C<⊥>.


=item Adding or subtracting a finite number and C<Inf>, in either order, gives C<Inf>.


=item Both C<+Inf> and C<-Inf> evaluate to C<Inf> inside the importing scope.


Bottom absorbs C<+>, C<->, C<*>, and C</> in either operand position, including operations with itself. Both C<+⊥> and C<-⊥> give C<⊥>.

C<⊥ == ⊥> is true, while C<⊥ == $number> and C<$number == ⊥> are false for other numeric values. The corresponding C<!=> comparisons give the opposite result. Bottom displays as ⊥ and is a defined singleton instance. Explicit Num conversion returns NaN; Int, Rat and FatRat conversions throw an exception.

Normalize an input with wheel($value), or compute its reciprocal with reciprocal($value). Reciprocal maps zero to Inf, Inf to zero, and bottom to itself.

Custom numeric types opt in with the exported WheelConvertible role and implement wheel-value, returning a defined Int, Rat, FatRat, Num or Complex without loss of information. Returning another adapter, a type object or an unsupported value raises an exception. Unsupported Numeric values are rejected rather than silently converted to Num.

The exact rational domain implements the wheel of fractions; floating-point and complex operations retain native rounding limitations. Equality normalizes operands, so external NaN compares as bottom and infinities of either sign compare equal.

=head1 EXPONENTIATION

C<**> is a lexical extension in addition to the basic wheel operations. A bottom exponent returns bottom, so C<2 ** (0/0)> gives C<⊥>. A zero exponent returns C<1> for every supported base, including zero, infinity, bottom and external NaN, following the empty-product convention. Bottom to any other exponent returns bottom.

Integral exponents use exponentiation by squaring through wheel multiplication; negative exponents first take the reciprocal. Rational bases retain exact arithmetic. Thus C<3 ** -2> is exactly C<1/9>, C<0 ** -1> gives C<Inf>, and C<Inf ** -1> gives C<0>. Complex exponents with zero imaginary part and integral real part use the same path.

Other exponents use native Raku exponentiation after input normalization, then normalize the result. These cases retain native rounding and domain behavior and are not specified by the wheel axioms. Infinities remain unsigned even in the exponent. Power retains native precedence and right associativity and is available through both import names.

=head1 MATHEMATICAL MODEL AND VALIDATION

The exact domain is the wheel of fractions over the rational field, with one unsigned infinity and bottom. Binary arithmetic follows the integer-pair model: addition maps (a,b),(c,d) to (ad+bc,bd), multiplication to (ac,bd), and reciprocal swaps the components. All nonzero numerators over zero represent infinity; (0,0) represents bottom. Rat and FatRat inputs with a zero denominator are normalized by the same rules.

Tests cover all eight axioms in Definition 1.1 of Jesper Carlström's Wheels — On Division by Zero, including the commutative monoid laws, reciprocal involution, modified distributivity and zero-term rules. The tests compare with an independent integer-pair oracle and inspect exact numerators and denominators, without relying on Wheel equality. Finite samples are regression checks, not a proof for all rational values.

Reference: L<https://www2.math.su.se/reports/2001/11/2001-11.pdf>.

The imported operators accept defined Numeric values or WheelConvertible adapters. They replace the lexical native operator dispatcher, so implicit arithmetic on strings is not supported. Convert such inputs explicitly before arithmetic. Operators outside the importing scope remain native.

=head1 INSTALLATION AND TESTING

From a source checkout with Raku, zef, and App::Prove6 available:

=begin code
zef install .
prove6 -I. -lv t
=end code

To run an example directly from the checkout, use C<raku -I. -e 'use Wheel; say 0 / 0'>. The C<-I.> option lets the loader resolve both provided names through C<META6.json>.

The tests cover arithmetic, equality, the symbolic alias, and lexical isolation. Use C<prove6> for the C<.rakutest> files.

=head1 AUTHOR

Fernando Correa de Oliveira <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 Fernando Correa de Oliveira.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
