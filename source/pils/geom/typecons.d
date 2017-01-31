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
    import std.algorithm.searching : canFind;
    import std.array : array;
    import std.range : cycle, take;
    import std.range.primitives;
}

/++
 + Ordered set of edges stored as an array of vertices.
 +/
struct Contour
{
    vec2d[] vertices;

    /++
     + Checks whether the given other contour or vector range is equal to this
     + contour by checking whether it contains the same vertices with the same
     + winding order.
     +
     + It is not required that the contour represented by the parameter has the
     + same starting index as the called contour. Consider a contour other that
     + is offset by two vertices and starts at the third vertex of the called
     + contour. It is still considered equal if the winding order is the same.
     + Check out the unit tests for some examples of equal and unequal contours.
     +
     + Params:
     +         other = Other contour or range of vec2d with length property
     +                 defined to check for equality with this contour
     +/
    bool opEquals(S)(S other) if(is(S == Contour) || isForwardRange!S && hasLength!S && is(ElementType!S == vec2d))
    {
        static if(is(S == Contour)) {
            auto otherVerts = other.vertices;
        } else {
            auto otherVerts = other;
        }

        if(vertices.length != otherVerts.length) {
            return false;
        }

        return cycle(vertices).take(vertices.length*2 - 1).canFind(otherVerts);
    }

    unittest
    {
        import std.range : retro;

        // Same order, is equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)])
        );

        // Second contour is offset to start at the third element of the first,
        // still equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            Contour([vec2d(1.0, 1.0), vec2d(0.0, 0.0), vec2d(1.0, 0.0)])
        );

        // Second contour is offset to start at the second element of the first,
        // still equal, also using array instead of contour
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            [vec2d(1.0, 0.0), vec2d(1.0, 1.0), vec2d(0.0, 0.0)]
        );

        // Second contour has reversed winding order,
        // not equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) !=
            [vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)].retro
        );

        // Count is different, not equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) !=
            [vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0), vec2d(0.0, 0.0)]
        );
    }

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
