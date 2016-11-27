module pils.geom.typecons;

public
{
    import gfm.math.vector;
    import gfm.math.quaternion;
    import gfm.math.matrix;
    // Line segments, planes, etc.
    import gfm.math.shapes;
}

/++
 + Ordered set of edges stored as an array of vertices.
 +/
struct Contour
{
    vec2d[] vertices;
}

/++
 + A polygon is a set of bounding contours of a domain.
 +/
struct Polygon
{
    Contour[] contours;
}

struct Region
{
    Polygon[] polygons;
}
