module pils.geom.util;

public
{
    import pils.geom.types;
    import gfm.math.funcs : clamp, lerp, radians, degrees;
}

private
{
    import std.algorithm;
    import std.range;
    import std.typecons;
    import std.math : approxEqual;
    import std.range.primitives;
    import std.traits : hasMember;
}

@property auto previousVertices(Contour c)
{
    return c.vertices
            .cycle()
            .drop(c.vertices.length - 1)
            .take(c.vertices.length);
}

@property auto nextVertices(Contour c)
{
    return c.vertices.cycle()
            .dropOne()
            .take(c.vertices.length);
}

/++
 + Checks if two vectors are approximately equal by judgement of the
 + std.math.approxEqual function applied to the internal static array embedded
 + in the vector.
 +
 + Only compares identical vector types with each other.
 +
 + Params:
 +       vec1 = The first vector that is compared to be almost equal to the other
 +       vec2 = The second vector that is compared to be almost equal to the other
 +
 + Returns:
 +       When vec1 and vec2 have approximately or precisely equal elements,
 +       true is returned, otherwise false is returned
 +/
bool almostEqual(T, V)(T vec1, T vec2, V maxAbsoluteDelta=0.00001) if(isVector!T)
{
    // 1e-5 = 0.00001 is the default: https://dlang.org/phobos/std_math.html#.approxEqual
    // 1e-2 = 0.01 is the default: https://dlang.org/phobos/std_math.html#.approxEqual
    return approxEqual(vec1.v[], vec2.v[], 0.01, maxAbsoluteDelta);
}

/++
 + Checks if two quaternions are approximately equal by judgement of the
 + std.math.approxEqual function applied to the internal static array embedded
 + in the vector that is a member of the quaternion and holds its data.
 +
 + Only compares identical quaternion types with each other.
 +
 + Params:
 +       quat1 = The first quaternion that is compared to be almost equal to the other
 +       quat2 = The second quaternion that is compared to be almost equal to the other
 +
 + Returns:
 +       When quat1 and quat2 have approximately or precisely equal elements,
 +       true is returned, otherwise false is returned
 +/
bool almostEqual(T, V)(T quat1, T quat2, V maxAbsoluteDelta=0.00001) if(isQuaternionInstantiation!T)
{
    // 1e-5 = 0.00001 is the default: https://dlang.org/phobos/std_math.html#.approxEqual
    return approxEqual(quat1.v.v[], quat2.v.v[], maxAbsoluteDelta);
}
