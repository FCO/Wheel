unit module Wheel::Kernel;
my class Bottom is Numeric {
    method gist { '⊥' }
    method raku { '⊥' }
    method Num { NaN }
    method Int { die 'Cannot convert bottom to Int' }
    method Rat { die 'Cannot convert bottom to Rat' }
    method FatRat { die 'Cannot convert bottom to FatRat' }
}
our constant BOTTOM = Bottom.new;
sub term:<⊥> is export { BOTTOM }
our role WheelConvertible is export { method wheel-value { ... } }
our sub wheel($x) is export {
    return BOTTOM if $x ~~ Bottom;
    if $x ~~ WheelConvertible {
        my $v = $x.wheel-value;
        die 'wheel-value must return a defined built-in numeric value'
            unless $v.defined && ($v ~~ Int|Rat|FatRat|Num|Complex) && $v !~~ WheelConvertible;
        return wheel($v);
    }
    die "Unsupported Wheel value: {$x.^name}" unless $x.defined && $x ~~ Int|Rat|FatRat|Num|Complex;
    if $x ~~ Rat|FatRat && $x.denominator == 0 {
        return $x.numerator == 0 ?? BOTTOM !! Inf;
    }
    if $x ~~ Complex {
        return BOTTOM if $x.re.isNaN || $x.im.isNaN;
        return Inf if $x.re.abs == Inf || $x.im.abs == Inf;
    }
    if $x ~~ Num {
        return BOTTOM if $x.isNaN;
        return Inf if $x.abs == Inf;
    }
    $x
}
sub infinite($x) { $x ~~ Num && $x == Inf }
sub exact($x) { $x ~~ Int|Rat|FatRat }
our sub calculate($op, $a, $b) is export {
    my $x = wheel($a); my $y = wheel($b);
    my $xb = $x ~~ Bottom; my $yb = $y ~~ Bottom;
    if $op eq '==' || $op eq '!=' {
        my $same = $xb || $yb ?? ($xb && $yb) !! ($x == $y);
        return $op eq '==' ?? $same !! !$same;
    }
    return BOTTOM if $xb || $yb;
    my $xi = infinite($x); my $yi = infinite($y);
    given $op {
        when '+' | '-' { return BOTTOM if $xi && $yi; return Inf if $xi || $yi }
        when '*' { return BOTTOM if ($xi && $y == 0) || ($yi && $x == 0); return Inf if $xi || $yi }
        when '/' {
            return BOTTOM if ($xi && $yi) || ($x == 0 && $y == 0);
            return Inf if $xi || $y == 0;
            return 0 if $yi;
        }
    }
    my $precise = exact($x) && exact($y);
    if $precise { $x = $x.FatRat; $y = $y.FatRat }
    my $result = do given $op {
        when '+' { $x + $y }; when '-' { $x - $y };
        when '*' { $x * $y }; when '/' { $x / $y };
    }
    return $result.Int if $precise && $result.denominator == 1;
    wheel($result)
}
our sub reciprocal($x) is export { calculate('/', 1, $x) }
our sub power($base, $exponent) is export {
    my $x = wheel($base);
    my $y = wheel($exponent);
    return BOTTOM if $y ~~ Bottom;
    return 1 if $y == 0;
    return BOTTOM if $x ~~ Bottom;

    my $real = $y ~~ Complex && $y.im == 0 ?? $y.re !! $y;
    if $real ~~ Real && !infinite($real) && $real == $real.Int {
        my Int $n = $real.Int;
        $x = reciprocal($x) if $n < 0;
        $n = $n.abs;
        my $result = 1;
        while $n {
            $result = calculate('*', $result, $x) if $n % 2;
            $n = $n div 2;
            $x = calculate('*', $x, $x) if $n;
        }
        return $result;
    }
    # Nonintegral and infinite exponents extend the wheel using native
    # exponentiation, followed by the same nonfinite normalization.
    wheel($x ** $y)
}
our sub unary($op, $value) is export {
    my $x = wheel($value);
    return $x if $x ~~ Bottom || infinite($x);
    $op eq '-' ?? -$x !! +$x
}
