/++
 + Contains math for lines, line segments and vectors.
 +/
module pils.geom.segments;

public
{
    import pils.geom.typecons;
}

private
{
    import pils.geom.util : direction, almostEqual;
    import std.math;
    import std.algorithm : sort;
    import std.typecons : Nullable;
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

    if(almostEqual(v1, v2))
    {
        return Parallelity.parallel;
    }
    else if(almostEqual(v1, -v2))
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
Parallelity parallelity(seg2d edge1, seg2d edge2)
{
    return parallelity(edge1.direction, edge2.direction);
}

version(none) {
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
    vec2d[] intersect(seg2d edge1, seg2d edge2, real intersectionMergeThreshold=0.0001)
    {
        void solveParameters(seg2d edge1, seg2d edge2, out real t, out real s)
        {
            vec2d edge1Direction = edge1.direction;
            vec2d edge2Direction = edge2.direction;

            t = ( edge2Direction.x * (edge1.a.y - edge2.a.y) - edge2Direction.y * (edge1.a.x - edge2.a.x)) / (-edge2Direction.x * edge1Direction.y + edge1Direction.x * edge2Direction.y);
            s = (-edge1Direction.y * (edge1.a.x - edge2.a.x) + edge1Direction.x * (edge1.a.y - edge2.a.y)) / (-edge2Direction.x * edge1Direction.y + edge1Direction.x * edge2Direction.y);
        }

        Nullable!vec2d intersectNonParallelSegments(seg2d edge1, seg2d edge2)
        {
            Nullable!vec2d intersection;
            real s, t;

            solveParameters(edge1, edge2, t, s);

            if(t >= 0 && t <= 1 && s >= 0 && s <= 1)
            {
                intersection = edge1.a + t * edge1.direction;
            }

            return intersection;
        }

        vec2d intersectNonParallelLines(seg2d edge1, seg2d edge2)
        {
            real s, t;
            solveParameters(edge1, edge2, t, s);
            return edge1.a + t * edge1.direction;
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

                        if(!lastDotProduct.isNull() && !approxEqual(dotProduct, lastDotProduct.get()))
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
                return (outerPoint - p1).squaredLength() <
                       (outerPoint - p2).squaredLength();
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
                seg2d edge1Orthogonal = seg2d(edge1.a - edge1OrthogonalDirection,
                                            edge1.a + edge1OrthogonalDirection);

                auto edge1OrthogonalIntersection = intersectNonParallelLines(edge1, edge1Orthogonal);
                auto edge2OrthogonalIntersection = intersectNonParallelLines(edge2, edge1Orthogonal);

                if(almostEqual(edge1OrthogonalIntersection, edge2OrthogonalIntersection))
                {
                    // lines are colinear and may share a common line segment
                    // If they do share a line segment, they will have two intersection
                    // points, otherwise zero or one.

                    auto points = [ edge1.a, edge1.b, edge2.a, edge2.b ];

                    // the two points in the middle are the intersections
                    intersections = sortDirectionally(points)[1..$-1];

                    if(almostEqual(intersections[0], intersections[1], intersectionMergeThreshold))
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
            seg2d(vec2d(0.0, 1.0), vec2d(0.0, 0.0)),
            seg2d(vec2d(0.6, 1.0), vec2d(0.4, 0.0))
        ).length == 0);

        assert(intersect(
            seg2d(vec2d(0.0, 2.0), vec2d(2.0, 0.0)),
            seg2d(vec2d(0.0, 0.0), vec2d(2.0, 2.0))
        ) == [ vec2d(1.0, 1.0) ]);

        assert(intersect(
            seg2d(vec2d(0.0, 0.0), vec2d(2.0, 2.0)),
            seg2d(vec2d(1.0, 1.0), vec2d(3.0, 3.0))
        ) == [
            vec2d(1.0, 1.0),
            vec2d(2.0, 2.0)
        ]);

        assert(intersect(
            seg2d(vec2d(2.0, 2.0), vec2d(0.0, 0.0)),
            seg2d(vec2d(1.0, 1.0), vec2d(3.0, 3.0))
        ) == [
            vec2d(1.0, 1.0),
            vec2d(2.0, 2.0)
        ]);

        assert(intersect(
            seg2d(vec2d(1.0, 1.0), vec2d(3.0, 3.0)),
            seg2d(vec2d(0.0, 0.0), vec2d(2.0, 2.0))
        ) == [
            vec2d(1.0, 1.0),
            vec2d(2.0, 2.0)
        ]);

        assert(intersect(
            seg2d(vec2d(1.0, 1.0), vec2d(10.0, 1.0)),
            seg2d(vec2d(1.0, 0.0), vec2d(10.0, 0.0))
        ).length == 0);

        // If lines touch but by very very little, only one intersection
        assert(intersect(
            seg2d(vec2d(0.0, 0.0), vec2d(5.0, 0.0)),
            seg2d(vec2d(5.0, 0.0), vec2d(10.0, 0.0))
        ) == [
            vec2d(5.0, 0.0)
        ]);

        // If lines are identical, returns the common start and end points
        assert(intersect(
            seg2d(vec2d(0.0, 0.0), vec2d(5.0, 0.0)),
            seg2d(vec2d(0.0, 0.0), vec2d(5.0, 0.0))
        ) == [
            vec2d(0.0, 0.0),
            vec2d(5.0, 0.0)
        ]);

        // If edge1.a == edge2.b && edge1.b == edge2.a
        // then the result should be the same
        assert(intersect(
            seg2d(vec2d(1.0, 0.0), vec2d(0.0, 1.0)),
            seg2d(vec2d(0.0, 1.0), vec2d(1.0, 0.0))
        ) == [
            vec2d(1.0, 0.0),
            vec2d(0.0, 1.0)
        ]);
    }
}

/++
 + Find the point on edge that is nearest to the given point.
 +
 + Params:
 +        edge  = The edge on which to find the nearest point
 +        point = The point from which to search for nearest point on edge
 +/
vec2d nearest(seg2d edge, vec2d point)
{
    vec2d start2Point = point - edge.a;
    vec2d start2End   = edge.b - edge.a;

    auto start2EndSqrMag = start2End.squaredLength();

    auto directionsDotProd = dot(start2Point, start2End);

    auto t = directionsDotProd / start2EndSqrMag;
    t = clamp(t, 0.0, 1.0);

    return edge.a + t*start2End;
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
Neighborhood findNeighborhood(T)(Segment!(T, 2) edge, Vector!(T, 2) point)
{
    return findNeighborhood(edge.a, edge.b, point);
}

/++
 +
 + See_Also: http://stackoverflow.com/a/1560510
 +/
Neighborhood findNeighborhood(T)(T segStart, T segEnd, T point) if(isVector!T && T.v.length == 2)
{
    auto sign = sgn((segEnd.x - segStart.x) * (point.y - segStart.y) -
                    (segEnd.y - segStart.y) * (point.x - segStart.x));

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
    seg2d xAxis = seg2d(vec2d(0.0, 0.0), vec2d(10.0, 0.0));

    assert(findNeighborhood(xAxis, vec2d(0.5, 0.0)) == Neighborhood.none);
    assert(findNeighborhood(xAxis, vec2d(100.5, 0.0)) == Neighborhood.none);
    assert(findNeighborhood(xAxis, vec2d(1.5, 1.0)) == Neighborhood.left);
    assert(findNeighborhood(xAxis, vec2d(1.5, -1.0)) == Neighborhood.right);
}

bool isLeftNeighborhood(seg2d edge, vec2d point)
{
    return findNeighborhood(edge, point) == Neighborhood.left;
}

bool isRightNeighborhood(seg2d edge, vec2d point)
{
    return findNeighborhood(edge, point) == Neighborhood.right;
}

bool isInnerNeighborhood(seg2d edge1, seg2d edge2, vec2d point)
{
    return false;
}

// Does not clamp to start and end of edge (line instead of line segment)
vec2d nearestOnLine(seg2d edge, vec2d point)
{
    vec2d start2Point = point - edge.a;
    vec2d start2End   = edge.b - edge.a;

    auto start2EndSqrMag = start2End.squaredLength();

    auto directionsDotProd = dot(start2Point, start2End);

    auto t = directionsDotProd / start2EndSqrMag;

    return edge.a + t*start2End;
}

unittest
{
    seg2d edge = seg2d(vec2d(0.0, 0.0), vec2d(10.0, 10.0));

    vec2d before = vec2d(-10.0, -12.0);
    vec2d middle = vec2d(5.0, 5.0) + vec2d(-1.0, 1.0);
    vec2d after = vec2d(10.0, 12.0);

    assert(almostEqual(nearest(edge, before), edge.a));
    assert(almostEqual(nearest(edge, middle), vec2d(5.0, 5.0)));
    assert(almostEqual(nearest(edge, after),  edge.b));
}
