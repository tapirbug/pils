module pils.geom.random;

public
{
    import pils.geom.types;
}

private
{
    import std.math : sqrt;
    import std.random;
}

/++
 + Selects a random point on a triangle
 +
 + See_Also:
 +     http://stackoverflow.com/questions/4778147/sample-random-point-in-triangle
 +/
@property Triangle!(T, N).point_t randomPoint(T, size_t N)(Triangle!(T, N) tri)
{
    auto u = uniform(0.0, 1.0);
    auto v = uniform(0.0, 1.0);

    return (1 - sqrt(u)) * tri.a + (sqrt(u) * (1 - v)) * tri.b + (sqrt(u) * v) * tri.c;
}

unittest
{
    triangle2d tri;
    tri.a = vec2d(0.0, 0.0);
    tri.b = vec2d(1.0, 0.0);
    tri.c = vec2d(1.0, 1.0);

    vec2d randomPoint = tri.randomPoint;
    assert(randomPoint.x >= 0.0);
    assert(randomPoint.y >= 0.0);
}
