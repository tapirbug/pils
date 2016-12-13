module pils.geom.minkowski;

public
{
    import pils.geom.typecons;
    import pils.geom.util;
    import pils.geom.sets;
    import std.range;
}

/++
 + Naïve minkowskiSum implementation.
 +/
auto minkowskiSum(Contour c1, Contour c2)
{
    return c1.vertices.map!((vert1) {
        return contour(c2.vertices.map!(vert2 => vert1+vert2)());
    })();
}

/++
 + Naïve minkowskiSum implementation. Will probably break with polygons with holes.
 +/
Polygon minkowskiSum(Polygon poly1, Polygon poly2)
{
    Polygon sum = poly1.dup;

    foreach(c1; poly1.contours)
    {
        foreach(c2; poly2.contours)
        {
            auto shape = polygon(minkowskiSum(c1, c2));
            sum = merge(sum, shape);
        }
    }

    foreach(c2; poly1.contours)
    {
        foreach(c1; poly2.contours)
        {
            auto shape = polygon(minkowskiSum(c1, c2));
            sum = merge(sum, shape);
        }
    }

    return sum;
}
