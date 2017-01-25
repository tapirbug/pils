module pils.geom.angles;

public
{
    import pils.geom.typecons;
}

private
{
    import std.math;
}

/++
 + Calculates the angle between two lines both starting in middle. One line will
 + extend to start and one line will extend to end.
 +
 + The resulting angle indicates how much the first line needs to be
 + counter-clockwise rotated to have the same slope as the second line.
 + The returned angle is guaranteed to be greater than or equal to zero and
 + smaller than or equal to 2π.
 +/
real angleBetween(vec2d start, vec2d middle, vec2d end)
{
    vec2d out1 = (start - middle).normalized;
    vec2d out2 = (end - middle).normalized;

    real angle = atan2(out2.y, out2.x) - atan2(out1.y, out1.x);
    return (angle < 0) ? (2*PI + angle) : angle;
}

unittest
{
    vec2d up = vec2d(0.0, 10.0);
    vec2d origin = vec2d(0.0, 0.0);
    vec2d right = vec2d(4.0, 0.0);
    vec2d left = vec2d(-1.0, 0.0);
    vec2d leftDown = vec2d(-1.0, -1.0);

    assert(approxEqual(angleBetween(up, origin, right), 1.5*PI));
    assert(approxEqual(angleBetween(right, origin, up), 0.5*PI));
    assert(approxEqual(angleBetween(leftDown, origin, left), 1.75*PI));
    assert(approxEqual(angleBetween(left, origin, leftDown), 0.25*PI));
}
