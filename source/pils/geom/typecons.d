module pils.geom.typecons;

public
{
    import gfm.math.vector;
    import gfm.math.quaternion;
    import gfm.math.matrix;
    // Line segments, planes, etc.
    import gfm.math.shapes;
    import gfm.math.funcs : clamp, lerp, radians, degrees;
    import std.algorithm.iteration : map;
    import std.array : array;
}

/++
 + Ordered set of edges stored as an array of vertices.
 +/
struct Contour
{
    vec2d[] vertices;

    @property auto dup() { return Contour(vertices.dup); }
}

/++
 + A polygon is a set of bounding contours of a domain.
 +/
struct Polygon
{
    Contour[] contours;

    @property auto dup() { return Polygon(contours.map!((d) => d.dup)().array); }
}

struct Region
{
    Polygon[] polygons;

    @property auto dup() { return Region(polygons.map!((p) => p.dup)().array); }
}
