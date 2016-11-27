module pils.geom.utils;

public
{
    import pils.geom.typecons;
}

private
{
    import std.algorithm;
    import std.range;
    import std.typecons;
}

/++
 + Constructs an n-sided contour from n vertices obtained from the given range.
 +/
Contour contour(V)(V vertices) if(isInputRange!V && is(ElementType!V == vec2d))
{
    return Contour(vertices.array);
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
