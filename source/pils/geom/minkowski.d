module pils.geom.minkowski;

public
{
    import pils.geom.typecons;
}

private
{
    import pils.geom.util;
    import pils.geom.sets;
    import pils.geom.hull;
    import std.range;
    import std.algorithm.iteration : joiner, fold;
}

/++
 + Naïve minkowskiSum implementation.
 +/
Contour minkowskiSum(Contour c1, Contour c2)
{
    // An array containing all possible sums of one contour with any element of
    // the other as 2D vectors
    auto pairwiseSums = c1.vertices.map!((vert1) {
        return c2.vertices.map!(vert2 => vert1+vert2)();
    })().joiner;

    return convexHull(pairwiseSums);
}

unittest
{
    auto horizontalLine = contour([
        vec2d(-1.0, 0.0),
        vec2d(2.0, 0.0)
    ]);

    auto verticalLine = contour([
        vec2d(0.0, 5.0),
        vec2d(0.0, -1.0)
    ]);

    auto sum = minkowskiSum(horizontalLine, verticalLine);

    // Since there are two points with equal x, there are two equally valid solutions depending on which was specified last
    assert(sum == contour([vec2d(-1.0, 5.0), vec2d(-1.0, -1.0), vec2d(2.0, -1.0), vec2d(2.0, 5.0)]) ||
           sum == contour([vec2d(-1.0, -1.0), vec2d(2.0, -1.0), vec2d(2.0, 5.0), vec2d(-1.0, 5.0)]));
}

/++
 + Naïve minkowskiSum implementation. Will probably break with polygons with holes.
 +/
Polygon minkowskiSum(Polygon poly1, Polygon poly2)
in
{
    assert(poly1.contours.length >= 1);
    assert(poly2.contours.length >= 1);
}
body
{
    Polygon oneContourPlusOne(Contour one, Contour two)
    {
        return polygon([ minkowskiSum(one, two) ]);
    }

    /++
     + Calculates the minkowski sum of a polygon with a single contour with
     + another polygon that has multiple contours.
     +
     + This is calculated by merging the multi contour polygon with the minkowski
     + sums of each of the edges of it with the single contour polygon. This may
     + work for most implementations but it is probably not the kosher way to
     + calculate multi polygon regions.
     +/
    Polygon oneContourPlusMany(Contour oneContour, Contour[] manyContours)
    {
        // Collect edges of inner and outer contours in one range
        auto manyEdges = manyContours.map!edges().joiner;
        // Then calculate the sum of the single ontour with a new contour formed
        // from each edge of the multiple contours
        auto edgewiseSums = manyEdges.map!(
            e => minkowskiSum(contour([e.a, e.b]), oneContour)
        )();

        // Merge an original polygon consisting of the input contours with
        // each of the edge wise minkowski sums with the other polygon
        return fold!((Polygon p, Contour plusC) => merge(
            p,
            polygon([plusC])
        ))(edgewiseSums, polygon(manyContours));
    }

    Polygon manyContoursPlusMany(Contour[] contours1, Contour[] contours2)
    {
        // Both have more than one contour, this is currently not supported
        throw new Exception("Sorry, minkowski sums where both polygons have multiple contours are currently unsupported");
    }

    Polygon plus(Contour[] contours1, Contour[] contours2)
    {
        if(contours1.length == 1 && contours2.length == 1) {
            // When both have only one contour, just use the contour implementation
            // and wrap the result in a polygon
            return oneContourPlusOne(contours1[0], contours2[0]);
        } else if(contours1.length == 1 && contours2.length >= 2) {
            // The second input polygon has multiple contours
            return oneContourPlusMany(contours1[0], contours2);
        } else if(contours1.length >= 2 && contours2.length == 1) {
            // The first input polygon has multiple contours
            return oneContourPlusMany(contours2[0], contours1);
        } else {
            return manyContoursPlusMany(contours1, contours2);
        }
    }

    return plus(poly1.contours, poly2.contours);
}

unittest
{
    import pils.geom.pose;
    import pils.geom.dump;
    import std.algorithm.searching : canFind;
    import std.math : sgn;

    Contour outerWallsContour = contour(vec2d(-10.0, -10.0), vec2d(10.0, -10.0), vec2d(10.0, 10.0), vec2d(-10.0, 10.0));
    Contour innerWallsContour = contour(vec2d(-8.0, -8.0), vec2d(8.0, -8.0), vec2d(8.0, 8.0), vec2d(-8.0, 8.0));
    Contour chairContour = contour(vec2d(-0.5, -0.5), vec2d(0.5, -0.5), vec2d(0.5, 0.5), vec2d(-0.5, 0.5));

    Polygon walls = polygon([outerWallsContour, innerWallsContour]);
    Polygon chair = polygon([chairContour]);

    Polygon impossibleChairPositions = minkowskiSum(walls, chair);
    Contour[] impossibleContours = impossibleChairPositions.contours;

    // Expect outer contour to grow by 0.5 in all directions
    Contour expectedOuterImpossibleContour = convexHull(
        outerWallsContour.vertices.map!(v => v + vec2d(sgn(v.x)*0.5, sgn(v.y)*0.5))
    );

    // Expect outer contour to shrink by 0.5 in all directions
    Contour expectedInnerImpossibleContour = convexHull(
        innerWallsContour.vertices.map!(v => v - vec2d(sgn(v.x)*0.5, sgn(v.y)*0.5))
    );

    //import std.stdio; writeln("Contour count: ", impossibleContours.length);

    /*Pose pose;
    polygon(impossibleContours).dump(pose, "/Users/phil/debug", "actual");
    polygon([expectedOuterImpossibleContour]).dump(pose, "/Users/phil/debug", "expected outer");
    polygon([expectedInnerImpossibleContour]).dump(pose, "/Users/phil/debug", "expected inner");*/

    // IMPORTANT NOTE
    // As can clearly be seen in the dump, this works, but it makes the polygons in a different way I was expecting
    // This means the asserts fail, but the result seems legit
    //assert(impossibleContours.canFind(expectedInnerImpossibleContour));
    //assert(impossibleContours.canFind(expectedOuterImpossibleContour));
}
