/++
 + Contains constructor functions for various geometry types.
 +/
module pils.geom.cons;

public
{
    import pils.geom.types;
}

private
{
    import std.array : array;
    import std.range.primitives : isInputRange, ElementType;
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
