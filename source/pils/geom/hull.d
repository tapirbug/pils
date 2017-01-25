module pils.geom.hull;

public
{
    import pils.geom.typecons;
}

private
{
    import pils.geom.segments;
    import pils.geom.util;
    import pils.geom.angles;
    import std.algorithm.searching;
    import std.algorithm.iteration;
    import std.range;
    import std.math;
}

/++
 + Calculates the convex hull of a finite set of points as a new contour.
 +
 + Put differently, this will approximate the smallest possible polygon that
 + contains all of the points in the given range.
 +
 + The Jarvis march algorithm is used for calculation of the convex hull,
 + sometimes also referred to as gift wrapping algorithm when applied to points
 + in two-dimensional space. It has O(nh) time complexity, n being the number of
 + points in the range and h being the number of points on the convex hull.
 +
 + In the degenerate case, where two vertices or less are passed, a contour will
 + be returned that contains the given vertices in the exact same order without
 + additional processing.
 +
 + Params:
 +         inputPointsRange = A finite forwards range returning at least three
 +                            consecutive points of a set of points to construct
 +                            a hull of
 +
 + See_Also:
 +         http://doc.cgal.org/latest/Convex_hull_2/,
 +         https://en.wikipedia.org/wiki/Convex_hull
 +         https://en.wikipedia.org/wiki/Gift_wrapping_algorithm
 +/
Contour convexHull(T)(T inputPointsRange) if(isForwardRange!T && !isInfinite!T)
{
    alias ElementType!T Point;

    // Convert to an array if not already random access
    static if(isRandomAccessRange!T) {
        alias inputPointsRange inputPoints;
    } else {
        auto inputPoints = inputPointsRange.array;
    }

    if(inputPoints.length < 3) {
        // Cannot really build a hull with 0-2 points, so just return a new
        // contour that contians the points that were passed in
        return Contour(inputPoints);
    }

    /++
     + Gets the index in inputPoints of the point that is most left of the line
     + represented by the two points from and to
     +/
    /+Point greatestLeftTurn(Point from, Point to) {
        return 0;
    }+/

    /++
     + Calculates whether testPoint is, left of the segment, on the segment,
     + or lies on the segment when extending the length, i.e. if the point
     + is everything but right of the segment.
     +/
    bool isRight(Point lineSegmentStart, Point lineSegmentEnd, Point testPoint)
    {
        return findNeighborhood(lineSegmentStart, lineSegmentEnd, testPoint) == Neighborhood.right;
    }

    Contour jarvis(T)(T pointSet) if(isRandomAccessRange!T)
    {
        // Initial value is leftmost point, since that is guaranteed to lie on the contour
        Point[] hull;
        Point pointOnHull = pointSet.minElement!(a => a.x);
        Point endPoint;

        do
        {
            hull ~= pointOnHull;
            endPoint = pointSet[0];

            for(size_t j = 1; j < pointSet.length; ++j)
            {
                if(endPoint == pointOnHull || isRight(hull[hull.length-1], endPoint, pointSet[j]))
                {
                    endPoint = pointSet[j];
                }
            }

            pointOnHull = endPoint;
        } while(!(endPoint == hull[0]));

        return contour(hull);
    }

    return jarvis(inputPoints);
}

unittest
{
    auto hull = convexHull([
        vec2d(1.0, 0.0), vec2d(-1.0, 0.0), vec2d(0.0, 0.5), vec2d(0.0, -0.5)
    ]);

    import std.stdio; writefln("Hull:\n%s", hull);

    assert(hull.vertices == [
        vec2d(-1.0, 0.0),
        vec2d(0.0, -0.5),
        vec2d(1.0, 0.0),
        vec2d(0.0, 0.5)
    ]);
}
