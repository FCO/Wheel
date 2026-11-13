[![Actions Status](https://github.com/FCO/Wheel/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Wheel/actions)

NAME
====

Wheel - Lexically scoped arithmetic with infinity and bottom for Raku.

SYNOPSIS
========

    use Wheel;

    say 1 / 0;       # Inf
    say 0 / 0;       # ⊥
    say -1 * Inf;    # Inf
    say Inf * -1;    # Inf
    say Inf / Inf;   # ⊥
    say ⊥ + 42;      # ⊥

DESCRIPTION
===========

Wheel exports arithmetic overloads and the term `⊥` (bottom). It extends ordinary real arithmetic with a single infinity represented by `Inf`, and a bottom value for indeterminate results.

Operations between Int, Rat and FatRat use exact rational arithmetic, returning Int for integral results and FatRat otherwise. Num and finite Complex arithmetic remain approximate. Both signs of infinity normalize to Inf; NaN (including a complex NaN component) normalizes to bottom. A complex value with an infinite component normalizes to Inf. These rules apply to operands and results.

SUPPORTED TYPES AND VALUES
==========================

The same operand types are accepted by `wheel`, `reciprocal`, the binary operators `+`, `-`, `*`, `/`, `**`, `==`, `!=`, and the unary operators `+` and `-`. Operands must be defined values.

  * `Int`: arbitrary-precision integers, for example `42` and `-7`.

  * `Rat`: rational numbers, including decimal literals such as `1.5` and values constructed with `Rat.new(1, 3)`.

  * `FatRat`: arbitrary-precision rational numbers, for example `FatRat.new(1, 3)`. Arithmetic between Int, Rat and FatRat is exact; integral results are returned as Int and nonintegral results as FatRat.

  * `Num`: floating-point numbers, for example `1e0` and `2.5e0`. Finite arithmetic retains native rounding. `Inf`, external `-Inf` and `NaN` are Num values, not separate types: infinities normalize to the single unsigned Inf and NaN normalizes to bottom.

  * `Complex`: complex numbers, for example `1+2i` or `Complex.new(1, 2)`. Finite arithmetic uses native complex arithmetic. A NaN component makes the whole value bottom; otherwise an infinite component makes it Inf. Complex zero requires both components to be zero.

  * `Bool`: `False` and `True` are accepted through their Int ancestry and act as zero and one in arithmetic.

  * `IntStr`, `RatStr`, `NumStr` and `ComplexStr`: Raku numeric allomorphs, such as those returned by `val('42')` or `val('1+2i')`, are accepted through their numeric ancestry. Their string representation is not used for calculation. An ordinary `Str` is not a numeric allomorph and must be explicitly converted.

  * `⊥`: the exported bottom singleton. Its implementation class is private; use the term rather than naming or constructing its class.

  * Types implementing `WheelConvertible`: implement `method wheel-value` to return a defined Int, Rat, FatRat, Num or Complex value without loss of information. Nested adapters and unsupported return values are rejected. The role is sufficient for entry to the operators; the adapter need not also implement Numeric.

Subclasses of supported numeric types are accepted through their ancestry, provided they retain compatible numeric behavior. Native machine values such as `int` and `num` are accepted when Raku boxes them into Int or Num at the call boundary. Abstract type objects such as `Int`, undefined values, plain strings and other Numeric implementations without a supported ancestry or the adapter role are rejected.

Rat and FatRat values with denominator zero are also accepted: a nonzero numerator gives Inf, while a zero numerator gives bottom. The same normalization applies to values returned by adapters. Accepted types can be mixed in either operand position; mixed Num or Complex calculations retain the native floating-point limitations. Nonintegral powers also follow native arithmetic, as described under EXPONENTIATION.

IMPORTS AND LEXICAL SCOPE
=========================

Use either `use Wheel;` or the symbolic alias `use ::('⊙');`. Both names load the same implementation and export the same operators and bottom term. The symbolic name requires the indirect module-name syntax; `use ⊙;` is not valid syntax.

Imports apply to the importing lexical scope and its nested scopes. They do not change enclosing or sibling scopes, or functions defined outside that scope. As with other Raku `use` declarations, imports are resolved at compile time.

    {
        use ::('⊙');
        say -1 * Inf;       # Inf
        {
            say Inf * -1;   # Inf (inherited import)
        }
    }
    say -1 * Inf;           # -Inf (native arithmetic)

ARITHMETIC RULES
================

For the supported real numeric types, the special cases are:

  * Zero divided by zero gives `⊥`.

  * A nonzero finite number divided by zero gives `Inf`, regardless of sign.

  * `Inf / 0` gives `Inf`; `Inf / Inf` gives `⊥`.

  * `Inf` divided by a finite number gives `Inf`; a finite number divided by `Inf` gives zero.

  * Zero multiplied by `Inf`, in either order, gives `⊥`.

  * A nonzero finite number multiplied by `Inf`, in either order, gives `Inf`, regardless of sign.

  * `Inf * Inf` gives `Inf`; `Inf + Inf` and `Inf - Inf` give `⊥`.

  * Adding or subtracting a finite number and `Inf`, in either order, gives `Inf`.

  * Both `+Inf` and `-Inf` evaluate to `Inf` inside the importing scope.

Bottom absorbs `+`, `-`, `*`, and `/` in either operand position, including operations with itself. Both `+⊥` and `-⊥` give `⊥`.

`⊥ == ⊥` is true, while `⊥ == $number` and `$number == ⊥` are false for other numeric values. The corresponding `!=` comparisons give the opposite result. Bottom displays as ⊥ and is a defined singleton instance. Explicit Num conversion returns NaN; Int, Rat and FatRat conversions throw an exception.

Normalize an input with wheel($value), or compute its reciprocal with reciprocal($value). Reciprocal maps zero to Inf, Inf to zero, and bottom to itself.

Custom numeric types opt in with the exported WheelConvertible role and implement wheel-value, returning a defined Int, Rat, FatRat, Num or Complex without loss of information. Returning another adapter, a type object or an unsupported value raises an exception. Unsupported Numeric values are rejected rather than silently converted to Num.

The exact rational domain implements the wheel of fractions; floating-point and complex operations retain native rounding limitations. Equality normalizes operands, so external NaN compares as bottom and infinities of either sign compare equal.

EXPONENTIATION
==============

`**` is a lexical extension in addition to the basic wheel operations. A bottom exponent returns bottom, so `2 ** (0/0)` gives `⊥`. A zero exponent returns `1` for every supported base, including zero, infinity, bottom and external NaN, following the empty-product convention. Bottom to any other exponent returns bottom.

Integral exponents use exponentiation by squaring through wheel multiplication; negative exponents first take the reciprocal. Rational bases retain exact arithmetic. Thus `3 ** -2` is exactly `1/9`, `0 ** -1` gives `Inf`, and `Inf ** -1` gives `0`. Complex exponents with zero imaginary part and integral real part use the same path.

Other exponents use native Raku exponentiation after input normalization, then normalize the result. These cases retain native rounding and domain behavior and are not specified by the wheel axioms. Infinities remain unsigned even in the exponent. Power retains native precedence and right associativity and is available through both import names.

MATHEMATICAL MODEL AND VALIDATION
=================================

The exact domain is the wheel of fractions over the rational field, with one unsigned infinity and bottom. Binary arithmetic follows the integer-pair model: addition maps (a,b),(c,d) to (ad+bc,bd), multiplication to (ac,bd), and reciprocal swaps the components. All nonzero numerators over zero represent infinity; (0,0) represents bottom. Rat and FatRat inputs with a zero denominator are normalized by the same rules.

Tests cover all eight axioms in Definition 1.1 of Jesper Carlström's Wheels — On Division by Zero, including the commutative monoid laws, reciprocal involution, modified distributivity and zero-term rules. The tests compare with an independent integer-pair oracle and inspect exact numerators and denominators, without relying on Wheel equality. Finite samples are regression checks, not a proof for all rational values.

Reference: [https://www2.math.su.se/reports/2001/11/2001-11.pdf](https://www2.math.su.se/reports/2001/11/2001-11.pdf).

The imported operators accept defined Numeric values or WheelConvertible adapters. They replace the lexical native operator dispatcher, so implicit arithmetic on strings is not supported. Convert such inputs explicitly before arithmetic. Operators outside the importing scope remain native.

INSTALLATION AND TESTING
========================

From a source checkout with Raku, zef, and App::Prove6 available:

    zef install .
    prove6 -I. -lv t

To run an example directly from the checkout, use `raku -I. -e 'use Wheel; say 0 / 0'`. The `-I.` option lets the loader resolve both provided names through `META6.json`.

The tests cover arithmetic, equality, the symbolic alias, and lexical isolation. Use `prove6` for the `.rakutest` files.

AUTHOR
======

Fernando Correa de Oliveira <fco@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2026 Fernando Correa de Oliveira.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

