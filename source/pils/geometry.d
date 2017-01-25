/+++
public
{
    import pils.geom.typecons;
}

private
{
    import std.range;
    import std.algorithm.iteration;
    import std.algorithm.mutation : swap;
    import std.algorithm.sorting : sort;
    import std.algorithm.searching;
    import std.conv : to;
    import std.typecons : tuple, Nullable;
    import std.math;
    import gfm.math.funcs : clamp, lerp;
    //import gl3n.math : approxEqual, clamp;
}

struct Polygon
{
    vec3d position = vec3d(0, 0, 0);
    quatd orientation = quatd.identity;

    Face[] faces;
}

struct Edge
{
    vec2d start;
    vec2d end;

    /++
     + Returns the direction of the edge as a directional vector. Note that the
     + returned vector is not normalized.
     +/
    @property vec2d direction()
    {
        return end - start;
    }
}

/++
 + Represents a polygon in 2D space with one or more contours.
 +
 + Note that the outermost contour must be counter-clockwise. Holes have
 + opposite winding order, which means a hole has clockwise winding order. If
 + that hole has in turn a hole, it will have counter-clockwise winding order
 + again.
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
    @property auto edges()
    {
        // Contains vertices but with the first vertex removed and added at the end
        auto nextVertices = vertices.cycle()
                                    .dropOne()
                                    .take(vertices.length);

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

    @property auto incidentEdges()
    {
        auto previousVertices = vertices.cycle()
                                        .drop(vertices.length - 1)
                                        .take(vertices.length);

        auto nextVertices = vertices.cycle()
                                    .dropOne()
                                    .take(vertices.length);

        return zip(
            zip(previousVertices, vertices).map!((pair) => Edge(pair[0], pair[1]))(),
            zip(vertices, nextVertices).map!((pair) => Edge(pair[0], pair[1]))()
        );
    }

    unittest
    {
        Face triangle = Face.tri(vec2d(-1.0, -1.0), vec2d(1.0, -1.0), vec2d(0.0, 1.0));

        assert(tuple(
            Edge(vec2d(0.0, 1.0), vec2d(-1.0, -1.0)),
            Edge(vec2d(-1.0, -1.0), vec2d(1.0, -1.0))
        ) == triangle.incidentEdges[0]);

        assert(tuple(
            Edge(vec2d(-1.0, -1.0), vec2d(1.0, -1.0)),
            Edge(vec2d(1.0, -1.0), vec2d(0.0, 1.0))
        ) == triangle.incidentEdges[1]);

        assert(tuple(
            Edge(vec2d(1.0, -1.0), vec2d(0.0, 1.0)),
            Edge(vec2d(0.0, 1.0), vec2d(-1.0, -1.0))
        ) == triangle.incidentEdges[2]);
    }

    /++
     + Obtains a range that yields the internal angle of each vertex in the
     + face.
     +/
    @property auto interiorAngles()
    {
        return incidentEdges.map!((incidents) {
            Edge before = incidents[0];
            Edge after = incidents[1];

            return angleBetween(after.end, after.start, before.start);
        })();
    }

    unittest
    {
        Face tri = Face.tri(
            vec2d(0.0, 0.0),
            vec2d(10.0, 0.0),
            vec2d(0.0, 10.0)
        );

        // All angles should amount to 180°
        assert(approxEqual(sum(tri.interiorAngles), PI));

        assert(approxEqual(tri.interiorAngles[0], 0.5*PI));
        assert(approxEqual(tri.interiorAngles[1], 0.25*PI));
        assert(approxEqual(tri.interiorAngles[2], 0.25*PI));
    }

    /++
     + Obtains a range that yields the external angle of each vertex in the
     + face.
     +/
    @property auto exteriorAngles()
    {
        return incidentEdges.map!((incidents) {
            Edge before = incidents[0];
            Edge after = incidents[1];

            return angleBetween(before.start, before.end, after.end);
        })();
    }

    unittest
    {
        Face tri = Face.tri(
            vec2d(0.0, 0.0),
            vec2d(10.0, 0.0),
            vec2d(0.0, 10.0)
        );

        assert(approxEqual(tri.exteriorAngles[0], 1.5*PI));
        assert(approxEqual(tri.exteriorAngles[1], 1.75*PI));
        assert(approxEqual(tri.exteriorAngles[2], 1.75*PI));
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
        return BooleanOperationEvaluator().subtract(this, other);
    }
}

private:

struct BooleanOperationEvaluator
{
    class CrossVertexDescriptor
    {
        CrossVertex vertex;
        bool isPrevious;

        this(CrossVertex vertex, bool isPrevious)
        {
            this.vertex = vertex;
            this.isPrevious = isPrevious;
        }

        @property bool isNext() { return !isPrevious; }
    }

    class CrossVertex
    {
        vec2d position;
        CrossVertexDescriptor previousEdgeDescriptor;
        CrossVertexDescriptor nextEdgeDescriptor;

        this(Edge previousEdge, Edge nextEdge)
        {
            previousEdgeDescriptor = new CrossVertexDescriptor(this, true);
            previousEdgeDescriptor = new CrossVertexDescriptor(this, false);
        }
    }

    CrossVertex[] processEdgeIntersections(ref Face faceA, ref Face faceB)
    {
        CrossVertex[] crossVertices;

        /++ Maps +/
        vec2d[size_t] vertexInsertions;

        void insertVerticesAfter(ref Face face, size_t afterIdx, vec2d[] vertices)
        {
            foreach(vertex; vertices)
            {
                if(!face.vertices.canFind(vertex))
                {
                    face.vertices.insertInPlace(afterIdx+1, vertex);
                }
            }
        }

        // Iterate with index over edges in forward direction but inversed order
        // so the idx can be used directly as insertion point without bringing
        // the vertices out of order
        foreach(edgeAStartIdx, Edge edgeA; faceA.edges.enumerate().retro())
        {
            foreach(edgeBStartIdx, Edge edgeB; faceB.edges.enumerate().retro())
            {
                vec2d[] intersections = intersect(edgeA, edgeB);

                /*if(intersections.length == 2)
                {
                    vec2d vertexAfter = faceA.vertices[(edgeAStartIdx+1) % faceA.vertices.length];
                    if((vertexAfter - intersections[0]).magnitude_squared <
                       (vertexAfter - intersections[1]).magnitude_squared)
                    {
                        swap(intersections[0], intersections[1]);
                    }
                }*/

                insertVerticesAfter(faceA, edgeAStartIdx, intersections);

                /*if(intersections.length == 2)
                {
                    vec2d vertexAfter = faceB.vertices[(edgeBStartIdx+1) % faceB.vertices.length];
                    if((vertexAfter - intersections[0]).magnitude_squared <
                       (vertexAfter - intersections[1]).magnitude_squared)
                    {
                        swap(intersections[0], intersections[1]);
                    }
                }*/
                insertVerticesAfter(faceB, edgeBStartIdx, intersections);

                foreach(intersection; intersections)
                {
                    /*auto crossVertex = new CrossVertex(edgeA, edgeB);

                    crossVertices ~= CrossVertex(intersection);*/
                }
            }
        }

        return crossVertices;
    }

    unittest
    {
        import std.stdio;

        Face tri = Face.tri(
            vec2d(0.0, 0.0),
            vec2d(1.0, 0.0),
            vec2d(0.0, 1.0)
        );

        Face quad = Face.quad(
            vec2d(0.4, -1.0),
            vec2d(0.6, -1.0),
            vec2d(0.6, 1.0),
            vec2d(0.4, 1.0)
        );

        auto evaluator = BooleanOperationEvaluator();
        evaluator.processEdgeIntersections(tri, quad);

        writeln(tri);
        writeln(quad);
    }

    /++
     + Returns a new face that contains only the regions of the first face
     + that are not also contained in the second face.
     +
     + Params:
     +      subtrahend = The face for which to return only the regions not also
     +                   occuppied by minuend
     +      minuend    = Indicates the regions not to include in the returned
     +                   face
     +/
    Face subtract(Face subtrahend, Face minuend)
    {
        processEdgeIntersections(subtrahend, minuend);

        return Face();
    }

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
+/
