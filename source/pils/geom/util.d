module pils.geom.util;

public
{
    import pils.geom.typecons;
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

/++
 + Constructs an n-sided contour from n vertices obtained from the given range.
 +/
Contour contour(V)(V vertices) if(isInputRange!V && is(ElementType!V == vec2d))
{
    return Contour(vertices.array);
}

/++
 + Constructs an n-sided contour from n vertices obtained from the given range,
 + where each vertex is either a dynamic array at least of length 2 or a static
 + array of length 2.
 +/
Contour contour(V)(V vertices) if(isInputRange!V && (is(ElementType!V == double[]) || is(ElementType!V == double[2])))
{
    return Contour(vertices.map!((v) => vec2d(v[0], v[1]))().array);
}

/++
 + Constructs an n-sided contour from n vectors given to this function.
 +
 + Examples:
 + -------------------------
 + Contour triangle = contour(vec2d(0, 0), vec2d(1, 0), vec2d(1, 1));
 + -------------------------
 +/
Contour contour(V...)(V vertices) if(vertices.length > 2)
{
    vec2d[] vertexArray;

    foreach(vertex; vertices)
    {
        vertexArray ~= vertex;
    }

    return Contour(vertexArray);
}

/++
 + Creates a polygon with the given contours.
 +/
Polygon polygon(C...)(C contours) if(is(ElementType!C == Contour))
{
    return Polygon(contours.array);
}

/++
 + Creates a polygon that has the given vertices as his only contour.
 +/
Polygon polygon(V...)(V vertices) if(is(V[0] == vec2d) && vertices.length >= 3)
{
    return Polygon([contour(vertices)]);
}

/++
 + Returns a range that contains all edges in the polygon in straight order
 + Starting at the seg2d from the first vertex to the second and ending with
 + the seg2d from the last vertex to the first.
 +/
@property auto edges(Contour c)
{
    return zip(c.vertices, c.nextVertices)
            .map!((pair) => seg2d(pair[0], pair[1]))();
}

unittest
{
    Contour triangle = contour(vec2d(-1.0, -1.0), vec2d(1.0, -1.0), vec2d(0.0, 1.0));
    seg2d[] edges;

    foreach(seg2d; triangle.edges)
    {
        edges ~= seg2d;
    }

    assert(edges.length == triangle.edges.length);

    assert(edges == [
        seg2d(vec2d(-1.0, -1.0), vec2d(1.0, -1.0)),
        seg2d(vec2d(1.0, -1.0), vec2d(0.0, 1.0)),
        seg2d(vec2d(0.0, 1.0), vec2d(-1.0, -1.0))
    ]);

    assert(edges == [ triangle.edges[0], triangle.edges[1], triangle.edges[2] ]);
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

@property auto incidentEdges(Contour c)
{
    return zip(
        zip(c.previousVertices, c.vertices).map!((pair) => seg2d(pair[0], pair[1]))(),
        zip(c.vertices, c.nextVertices).map!((pair) => seg2d(pair[0], pair[1]))()
    );
}

unittest
{
    Contour triangle = contour(vec2d(-1.0, -1.0), vec2d(1.0, -1.0), vec2d(0.0, 1.0));

    assert(tuple(
        seg2d(vec2d(0.0, 1.0), vec2d(-1.0, -1.0)),
        seg2d(vec2d(-1.0, -1.0), vec2d(1.0, -1.0))
    ) == triangle.incidentEdges[0]);

    assert(tuple(
        seg2d(vec2d(-1.0, -1.0), vec2d(1.0, -1.0)),
        seg2d(vec2d(1.0, -1.0), vec2d(0.0, 1.0))
    ) == triangle.incidentEdges[1]);

    assert(tuple(
        seg2d(vec2d(1.0, -1.0), vec2d(0.0, 1.0)),
        seg2d(vec2d(0.0, 1.0), vec2d(-1.0, -1.0))
    ) == triangle.incidentEdges[2]);
}

/++
 + Gets the normalized direction from point a to point b of the given segment.
 +/
@property auto direction(T)(T seg) if(isSegment!T)
{
    return (seg.b - seg.a).normalized;
}

unittest
{
    auto left = direction(seg2d(vec2d(1.0, 0.0), vec2d(-1.1, 0.0)));
    assert(almostEqual(left, vec2d(-1.0, 0.0)));
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
