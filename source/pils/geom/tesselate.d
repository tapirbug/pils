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

@property TriangleStrip[] triangleStrips(Polygon poly)
{
    gpc_polygon polygon = gpcPolygon(poly);

    gpc_tristrip tristrip;
    gpc_polygon_to_tristrip(&polygon, &tristrip);

    auto strips = tristrip.strip[0..tristrip.num_strips];

    TriangleStrip[] copiedStrips;
    foreach(strip; strips)
    {
        auto vertices = strip.vertex[0..strip.num_vertices];
        vec2d[] stripVerts;

        foreach(vertex; vertices)
        {
            stripVerts ~= vec2d(vertex.x, vertex.y);
        }

        copiedStrips ~= TriangleStrip(stripVerts);
    }

    gpc_free_polygon(&polygon);
    gpc_free_tristrip(&tristrip);

    return copiedStrips;
}

struct TriangleStrip
{
    vec2d[] strip;
    bool flipOrder = false;

    @property bool empty() const {
        return strip.length <= 3;
    }

    @property triangle2d front() {
        if(flipOrder)
        {
            return triangle2d(strip[0], strip[2], strip[1]);
        }
        else
        {
            return triangle2d(strip[0], strip[1], strip[2]);
        }
    }

    void popFront() {
        strip = strip[1 .. $];
        flipOrder = !flipOrder;
    }
}

unittest
{
    import std.array;
    
    auto quad = polygon(
        vec2d(0.0, 0.0),
        vec2d(1.0, 0.0),
        vec2d(1.0, 1.0),
        vec2d(0.0, 1.0),
        vec2d(0.5, 0.5)
    );

    auto strips = quad.triangleStrips.array;

    assert(strips.length == 1);
}

private:
