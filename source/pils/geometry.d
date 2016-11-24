
public
{
    import gl3n.linalg;
    import pils.quat4d;
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
    import gl3n.math : almost_equal, clamp;
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
        assert(almost_equal(sum(tri.interiorAngles), PI));

        assert(almost_equal(tri.interiorAngles[0], 0.5*PI));
        assert(almost_equal(tri.interiorAngles[1], 0.25*PI));
        assert(almost_equal(tri.interiorAngles[2], 0.25*PI));
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

        assert(almost_equal(tri.exteriorAngles[0], 1.5*PI));
        assert(almost_equal(tri.exteriorAngles[1], 1.75*PI));
        assert(almost_equal(tri.exteriorAngles[2], 1.75*PI));
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

/++
 + Calculates the angle between two lines both starting in middle. One line will
 + extend to start and one line will extend to end.
 +
 + The resulting angle indicates how much the first line needs to be
 + counter-clockwise rotated to have the same slope as the second line.
 + The returned angle is guaranteed to be greater than or equal to zero and
 + smaller than or equal to 2π.
 +/
real angleBetween(vec2d start, vec2d middle, vec2d end)
{
    vec2d out1 = (start - middle).normalized;
    vec2d out2 = (end - middle).normalized;

    real angle = atan2(out2.y, out2.x) - atan2(out1.y, out1.x);
    return (angle < 0) ? (2*PI + angle) : angle;
}

unittest
{
    vec2d up = vec2d(0.0, 10.0);
    vec2d origin = vec2d(0.0, 0.0);
    vec2d right = vec2d(4.0, 0.0);
    vec2d left = vec2d(-1.0, 0.0);
    vec2d leftDown = vec2d(-1.0, -1.0);

    assert(almost_equal(angleBetween(up, origin, right), 1.5*PI));
    assert(almost_equal(angleBetween(right, origin, up), 0.5*PI));
    assert(almost_equal(angleBetween(leftDown, origin, left), 1.75*PI));
    assert(almost_equal(angleBetween(left, origin, leftDown), 0.25*PI));
}

enum Parallelity
{
    /++ Neither Parallel nor antiparallel +/
    none,
    /++ Parallel or near parallel +/
    parallel,
    /++ Antiparallel or near antiparallel +/
    antiparallel
}

/++
 + Checks whether two vectors are parallel, antiparallel or not at all parallel.
 + Note that due to floating point imprecisions vectors are treated as parallel
 + once they are close enough to being near parallel.
 +/
Parallelity parallelity(vec2d v1, vec2d v2)
{
    v1.normalize();
    v2.normalize();

    if(almost_equal(v1, v2))
    {
        return Parallelity.parallel;
    }
    else if(almost_equal(v1, -v2))
    {
        return Parallelity.antiparallel;
    }
    else
    {
        return Parallelity.none;
    }
}

unittest
{
    assert(parallelity(vec2d(5.0, 5.0), vec2d(1.0, 1.0)) == Parallelity.parallel);
    assert(parallelity(vec2d(5.0, 5.0), vec2d(-1.0, -1.0)) == Parallelity.antiparallel);
    assert(parallelity(vec2d(1.0, 0.0), vec2d(0.0, -1.0)) == Parallelity.none);
}

/++
 + Checks whether the given edges are near parallel, near antiparallel or not at
 + all parallel.
 +/
Parallelity parallelity(Edge edge1, Edge edge2)
{
    return parallelity(edge1.direction, edge2.direction);
}

/++
 + Returns the intersection points of two edges.
 +
 + If the two edges to not intersect, an empty array is returned.
 +
 + If they do intersect, returns one intersection point.
 +
 + If the two edges share a common line segment, the start and end of that
 + segment are returned as intersection points.
 +/
vec2d[] intersect(Edge edge1, Edge edge2)
{
    void solveParameters(Edge edge1, Edge edge2, out real t, out real s)
    {
        vec2d edge1Direction = edge1.direction;
        vec2d edge2Direction = edge2.direction;

        t = ( edge2Direction.x * (edge1.start.y - edge2.start.y) - edge2Direction.y * (edge1.start.x - edge2.start.x)) / (-edge2Direction.x * edge1Direction.y + edge1Direction.x * edge2Direction.y);
        s = (-edge1Direction.y * (edge1.start.x - edge2.start.x) + edge1Direction.x * (edge1.start.y - edge2.start.y)) / (-edge2Direction.x * edge1Direction.y + edge1Direction.x * edge2Direction.y);
    }

    Nullable!vec2d intersectNonParallelSegments(Edge edge1, Edge edge2)
    {
        Nullable!vec2d intersection;
        real s, t;

        solveParameters(edge1, edge2, t, s);

        if(t >= 0 && t <= 1 && s >= 0 && s <= 1)
        {
            intersection = edge1.start + t * edge1.direction;
        }

        return intersection;
    }

    vec2d intersectNonParallelLines(Edge edge1, Edge edge2)
    {
        real s, t;
        solveParameters(edge1, edge2, t, s);
        return edge1.start + t * edge1.direction;
    }

    vec2d[] sortDirectionally(vec2d[] points) {
        size_t outerIdx = -1;

        for(size_t i1 = 0; i1 < points.length && outerIdx == -1; ++i1)
        {
            Nullable!(real, real.max) lastDotProduct;
            bool allSameDirection = true;

            for(size_t i2 = 0; i2 < points.length && allSameDirection; ++i2)
            {
                if(i1 != i2 && points[i1] != points[i2])
                {
                    real dotProduct = dot(points[i1], points[i2]);

                    if(!lastDotProduct.isNull() && !almost_equal(dotProduct, lastDotProduct.get()))
                    {
                        allSameDirection = false;
                    }

                    lastDotProduct = dotProduct;
                }
            }

            if(allSameDirection)
            {
                outerIdx = i1;
            }
        }

        assert(outerIdx != -1);
        vec2d outerPoint = points[outerIdx];

        bool hasFirstLessDistanceToOuter(vec2d p1, vec2d p2)
        {
            return (outerPoint - p1).magnitude_squared <
                   (outerPoint - p2).magnitude_squared;
        }

        auto sorted = sort!(hasFirstLessDistanceToOuter)(points)[0..$];

        return array(sorted);
    }

    vec2d[] intersections;

    auto edgeParalellity = parallelity(edge1, edge2);

    final switch(edgeParalellity)
    {
        case Parallelity.none:
            // lines are neither parallel, antiparallel or colinear, they have
            // zero or one intersection point.

            auto intersection = intersectNonParallelSegments(edge1, edge2);
            if(!intersection.isNull())
            {
                intersections ~= intersection;
            }

            break;

        case Parallelity.parallel:
        case Parallelity.antiparallel:
            // flip coordinates
            vec2d edge1OrthogonalDirection = edge1.direction.yx;
            edge1OrthogonalDirection.y = -edge1OrthogonalDirection.y;
            Edge edge1Orthogonal = Edge(edge1.start - edge1OrthogonalDirection,
                                        edge1.start + edge1OrthogonalDirection);

            auto edge1OrthogonalIntersection = intersectNonParallelLines(edge1, edge1Orthogonal);
            auto edge2OrthogonalIntersection = intersectNonParallelLines(edge2, edge1Orthogonal);

            if(almost_equal(edge1OrthogonalIntersection, edge2OrthogonalIntersection))
            {
                // lines are colinear and may share a common line segment
                // If they do share a line segment, they will have two intersection
                // points, otherwise zero or one.

                auto points = [ edge1.start, edge1.end, edge2.start, edge2.end ];

                // the two points in the middle are the intersections
                intersections = sortDirectionally(points)[1..$-1];

                if(almost_equal(intersections[0], intersections[1], 0.0001))
                {
                    // If lines touch by very very little, only one intersection
                    // is returned
                    intersections = intersections[1..$];
                }
            }
            break;
    }

    return intersections;
}

unittest
{
    assert(intersect(
        Edge(vec2d(0.0, 1.0), vec2d(0.0, 0.0)),
        Edge(vec2d(0.6, 1.0), vec2d(0.4, 0.0))
    ).empty);

    assert(intersect(
        Edge(vec2d(0.0, 2.0), vec2d(2.0, 0.0)),
        Edge(vec2d(0.0, 0.0), vec2d(2.0, 2.0))
    ) == [ vec2d(1.0, 1.0) ]);

    assert(intersect(
        Edge(vec2d(0.0, 0.0), vec2d(2.0, 2.0)),
        Edge(vec2d(1.0, 1.0), vec2d(3.0, 3.0))
    ) == [
        vec2d(1.0, 1.0),
        vec2d(2.0, 2.0)
    ]);

    assert(intersect(
        Edge(vec2d(2.0, 2.0), vec2d(0.0, 0.0)),
        Edge(vec2d(1.0, 1.0), vec2d(3.0, 3.0))
    ) == [
        vec2d(1.0, 1.0),
        vec2d(2.0, 2.0)
    ]);

    assert(intersect(
        Edge(vec2d(1.0, 1.0), vec2d(3.0, 3.0)),
        Edge(vec2d(0.0, 0.0), vec2d(2.0, 2.0))
    ) == [
        vec2d(1.0, 1.0),
        vec2d(2.0, 2.0)
    ]);

    assert(intersect(
        Edge(vec2d(1.0, 1.0), vec2d(10.0, 1.0)),
        Edge(vec2d(1.0, 0.0), vec2d(10.0, 0.0))
    ).empty);

    // If lines touch but by very very little, only one intersection
    assert(intersect(
        Edge(vec2d(0.0, 0.0), vec2d(5.0, 0.0)),
        Edge(vec2d(5.0, 0.0), vec2d(10.0, 0.0))
    ) == [
        vec2d(5.0, 0.0)
    ]);

    // If lines are identical, returns the common start and end points
    assert(intersect(
        Edge(vec2d(0.0, 0.0), vec2d(5.0, 0.0)),
        Edge(vec2d(0.0, 0.0), vec2d(5.0, 0.0))
    ) == [
        vec2d(0.0, 0.0),
        vec2d(5.0, 0.0)
    ]);

    // If edge1.start == edge2.end && edge1.end == edge2.start
    // then the result should be the same
    assert(intersect(
        Edge(vec2d(1.0, 0.0), vec2d(0.0, 1.0)),
        Edge(vec2d(0.0, 1.0), vec2d(1.0, 0.0))
    ) == [
        vec2d(1.0, 0.0),
        vec2d(0.0, 1.0)
    ]);
}

/++
 + Find the point on edge that is nearest to the given point.
 +
 + Params:
 +        edge  = The edge on which to find the nearest point
 +        point = The point from which to search for nearest point on edge
 +/
vec2d nearest(Edge edge, vec2d point)
{
    vec2d start2Point = point - edge.start;
    vec2d start2End   = edge.end - edge.start;

    auto start2EndSqrMag = start2End.length_squared;

    auto directionsDotProd = dot(start2Point, start2End);

    auto t = directionsDotProd / start2EndSqrMag;
    t = clamp(t, 0.0, 1.0);

    return edge.start + t*start2End;
}

enum Neighborhood
{
    /++
     + The point is an element of the line and neither left nor right of it.
     +/
    none,
    /++
     + The point is in the left neighborhood of the line.
     +/
    left,
    /++
     + The point is in the right neighborhood of the line.
     +/
    right
}

/++
 +
 + See_Also: http://stackoverflow.com/a/1560510
 +/
Neighborhood findNeighborhood(Edge edge, vec2d point)
{
    auto sign = sgn((edge.end.x - edge.start.x) * (point.y - edge.start.y) -
                    (edge.end.y - edge.start.y) * (point.x - edge.start.x));

    if(sign == -1)
    {
        return Neighborhood.right;
    }
    else if(sign == 1)
    {
        return Neighborhood.left;
    }
    else
    {
        assert(sign == 0);
        return Neighborhood.none;
    }
}

unittest
{
    Edge xAxis = Edge(vec2d(0.0, 0.0), vec2d(10.0, 0.0));

    assert(findNeighborhood(xAxis, vec2d(0.5, 0.0)) == Neighborhood.none);
    assert(findNeighborhood(xAxis, vec2d(100.5, 0.0)) == Neighborhood.none);
    assert(findNeighborhood(xAxis, vec2d(1.5, 1.0)) == Neighborhood.left);
    assert(findNeighborhood(xAxis, vec2d(1.5, -1.0)) == Neighborhood.right);
}

bool isLeftNeighborhood(Edge edge, vec2d point)
{
    return findNeighborhood(edge, point) == Neighborhood.left;
}

bool isRightNeighborhood(Edge edge, vec2d point)
{
    return findNeighborhood(edge, point) == Neighborhood.right;
}

bool isInnerNeighborhood(Edge edge1, Edge edge2, vec2d point)
{
    return false;
}

// Does not clamp to start and end of edge (line instead of line segment)
vec2d nearestOnLine(Edge edge, vec2d point)
{
    vec2d start2Point = point - edge.start;
    vec2d start2End   = edge.end - edge.start;

    auto start2EndSqrMag = start2End.length_squared;

    auto directionsDotProd = dot(start2Point, start2End);

    auto t = directionsDotProd / start2EndSqrMag;

    return edge.start + t*start2End;
}

unittest
{
    Edge edge = Edge(vec2d(0.0, 0.0), vec2d(10.0, 10.0));

    vec2d before = vec2d(-10.0, -12.0);
    vec2d middle = vec2d(5.0, 5.0) + vec2d(-1.0, 1.0);
    vec2d after = vec2d(10.0, 12.0);

    assert(almost_equal(nearest(edge, before), edge.start));
    assert(almost_equal(nearest(edge, middle), vec2d(5.0, 5.0)));
    assert(almost_equal(nearest(edge, after),  edge.end));
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
