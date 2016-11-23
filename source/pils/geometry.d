
public
{
    import gl3n.linalg;
    import pils.quat4d;
}

private
{
    import std.range;
    import std.algorithm.iteration;
    import std.conv : to;
}

struct Polygon
{
    vec3d position = vec3d(0, 0, 0);
    quat4d orientation = quat4d.identity;

    @property vec3d unitX() { return orientation * vec3d(1, 0, 0); }
    @property vec3d unitY() { return orientation * vec3d(0, 1, 0); }
    @property vec3d unitZ() { return orientation * vec3d(0, 0, 1); }

    Face[] faces;
}

struct Edge
{
    vec2d start;
    vec2d end;
}

/++
 + Represents a polygon in 2D space.
 +/
struct Face
{
    /++
     + Constructs an n-sided polygon from n vectors where n is at least three.
     +
     + Examples:
     + -------------------------
     + Face triangle = Face.polygon(vec2d(0, 0), vec2d(1, 0), vec2d(1, 1));
     + -------------------------
     +/
    static Face polygon(V...)(V vertices) if(is(V[0] == vec2d) && vertices.length >= 3)
    {
        vec2d[] vertexArray;

        foreach(vertex; vertices)
        {
            vertexArray ~= vertex;
        }

        return Face(vertexArray);
    }

    static Face tri(vec2d v1, vec2d v2, vec2d v3)
    {
        return polygon(v1, v2, v3);
    }

    static Face quad(vec2d v1, vec2d v2, vec2d v3, vec2d v4)
    {
        return polygon(v1, v2, v3, v4);
    }

    /++
     + Represents the vertices of the face in two-dimensional space.
     +/
    vec2d[] vertices;
    /++
     + Contains the indexes where a new contour starts. The first contour,
     + starting at index 0 is implicit and must not be contained in this list.
     +/
    size_t[] contourSplits;

    /++
     + Returns a range that iterates over the contours of this face.
     + The contours are themselves faces but with exactly one contour.
     +/
    @property auto contours()
    {
        struct ContourRange
        {
            vec2d[] vertices;
            size_t[] contourSplits;
            size_t frontOffset = 0;

            @property bool empty() const
            {
                return frontOffset == -1;
            }

            @property Face front()
            {
                return Face(vertices[frontOffset .. (contourSplits.empty) ? vertices.length : contourSplits[0]]);
            }

            void popFront()
            {
                if(contourSplits.empty)
                {
                    frontOffset = -1;
                }
                else
                {
                    frontOffset = contourSplits[0];
                    contourSplits = contourSplits[1 .. $];
                }
            }

            @property size_t length()
            {
                return contourSplits.length + 1;
            }

            Face opIndex(size_t idx)
            in
            {
                assert(idx >= 0 && idx < length ||
                       idx == 0 && contourSplits.empty);
            }
            body
            {
                size_t start = (idx > 0) ? contourSplits[idx - 1] : 0;
                size_t end = (idx < contourSplits.length) ? contourSplits[idx] : vertices.length;
                return Face(vertices[start..end]);
            }

            @property ContourRange save()
            {
                return ContourRange(vertices, contourSplits, frontOffset);
            }
        }

        return ContourRange(vertices, contourSplits);
    }

    unittest
    {
        // A face with two contours: an outer and an inner quad
        vec2d[] verts = [
            vec2d(-1.0, -1.0),
            vec2d(1.0, -1.0),
            vec2d(1.0, 1.0),
            vec2d(-1.0, 1.0),

            vec2d(-0.5, -0.5),
            vec2d(0.5, -0.5),
            vec2d(0.5, 0.5),
            vec2d(-0.5, 0.5)
        ];
        size_t[] splits = [ 4 ];
        Face face = Face(verts, splits);

        assert(face.contours.length == 2);
        assert(face.contours[0] == Face(verts[0..4]));
        assert(face.contours[1] == Face(verts[4..$]));
    }

    /++
     + Returns a range that contains all edges in the polygon in straight order
     + Starting at the edge from the first vertex to the second and ending with
     + the edge from the last vertex to the first.
     +/
    @property auto edges() {
        // Contains vertices but with the first vertex removed and added at the end
        auto nextVertices = vertices.cycle()
                                    .take(vertices.length + 1)
                                    .dropOne();

        return zip(vertices, nextVertices)
               .map!((pair) => Edge(pair[0], pair[1]))();
    }

    unittest
    {
        Face triangle = Face.tri(vec2d(-1.0, -1.0), vec2d(1.0, -1.0), vec2d(0.0, 1.0));
        Edge[] edges;

        foreach(edge; triangle.edges)
        {
            edges ~= edge;
        }

        assert(edges.length == triangle.edges.length);

        assert(edges == [
            Edge(vec2d(-1.0, -1.0), vec2d(1.0, -1.0)),
            Edge(vec2d(1.0, -1.0), vec2d(0.0, 1.0)),
            Edge(vec2d(0.0, 1.0), vec2d(-1.0, -1.0))
        ]);

        assert(edges == [ triangle.edges[0], triangle.edges[1], triangle.edges[2] ]);
    }

    /++
     + Returns an array of points where each three consecutive points form one
     + triangle of the face in model space. All triangles together occupy the
     + exact same area as the original polygon.
     +/
    vec2d[] triangulate()
    {
        vec2d[] triangles;

        assert(false);

        //return triangles;
    }

    /++
     + Calculates a set of new faces that, taken together, contain the union of
     + this face and the other face.
     +
     + Params:
     +      other = The face to calculate the union with this face
     +
     + Returns: New faces containing the vertices of a union between this and other
     +/
    Face subtract(Face other)
    {
        assert(false);
    }

    Face add(Face other)
    {
        assert(false);
    }

    @property real area()
    {
        assert(false);
    }

    /*@property bool isConvex()
    {

    }

    @property bool isConcave()
    {

    }*/
}

unittest
{
    Face tri = Face.tri(
        vec2d(-1.0, -1.0),
        vec2d(1.0, -1.0),
        vec2d(0.0, 1.0)
    );

    Face quad = Face.quad(
        vec2d(-1.0, 0.0),
        vec2d(1.0, 0.0),
        vec2d(1.0, 3.0),
        vec2d(-1.0, 3.0)
    );

    /*Face trapezoid = tri.subtract(quad);

    assert(trapezoid.vertices.length == 4);
    assert(trapezoid.vertices[0].y <= 0.0);
    assert(trapezoid.vertices[1].y <= 0.0);
    assert(trapezoid.vertices[2].y <= 0.0);
    assert(trapezoid.vertices[3].y <= 0.0);

    assert(trapezoid.edges.length == 4);*/


    // TODO test polygon with holes
    // TODO test polygon with self-touching vertex that is used by two independent edges
    // TODO test polygon that intersects itself
    // TODO test two polygons that share a common edge
}
