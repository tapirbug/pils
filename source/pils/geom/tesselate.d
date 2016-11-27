module pils.geom.tesselate;
@trusted:

public
{
    import pils.geom.typecons;
}

private
{
    import pils.geom.util;
    import deimos.gpc;
    import std.range;
}

gpc_polygon gpcPolygon(ref Polygon poly)
{
    gpc_polygon polygon;

    foreach(contour; poly.contours)
    {
        gpc_vertex[] vertices = new gpc_vertex[contour.vertices.length];

        foreach(contourVertex, ref gpcVertex; lockstep(contour.vertices, vertices))
        {
            gpcVertex.x = contourVertex.x;
            gpcVertex.y = contourVertex.y;
        }

        gpc_vertex_list vertexList = gpc_vertex_list(
            cast(int) vertices.length,
            vertices.ptr
        );

        gpc_add_contour(&polygon, &vertexList, 0);
    }

    return polygon;
}

vec2d[][] toTriangleStrips(Polygon poly)
{
    gpc_polygon polygon = gpcPolygon(poly);

    gpc_tristrip tristrip;
    gpc_polygon_to_tristrip(&polygon, &tristrip);

    auto strips = tristrip.strip[0..tristrip.num_strips];

    vec2d[][] copiedStrips;
    foreach(strip; strips)
    {
        auto vertices = strip.vertex[0..strip.num_vertices];
        vec2d[] stripVerts;

        foreach(vertex; vertices)
        {
            stripVerts ~= vec2d(vertex.x, vertex.y);
        }

        copiedStrips ~= stripVerts;
    }

    gpc_free_polygon(&polygon);
    gpc_free_tristrip(&tristrip);

    return copiedStrips;
}

unittest
{
    auto quad = polygon(
        vec2d(0.0, 0.0),
        vec2d(1.0, 0.0),
        vec2d(1.0, 1.0),
        vec2d(0.0, 1.0),
        vec2d(0.5, 0.5)
    );

    vec2d[][] strips = quad.toTriangleStrips();

    assert(strips.length == 1);
}

private:
