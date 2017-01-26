module pils.geom.sets;

public
{
    import pils.geom.typecons;
}

private
{
    import pils.geom.util;
    import pils.geom.tesselate : gpcPolygon;
    import deimos.gpc;
    import std.algorithm : map;
    import std.array;
}

Polygon merge(Polygon inputPolyA, Polygon inputPolyB)
{
    return clip(gpc_op.GPC_UNION, inputPolyA, inputPolyB);
}

Polygon merge(Contour inputContourA, Contour inputContourB)
{
    return merge(
        polygon([inputContourA]),
        polygon([inputContourB])
    );
}

Polygon intersect(Polygon inputPolyA, Polygon inputPolyB)
{
    return clip(gpc_op.GPC_INT, inputPolyA, inputPolyB);
}

Polygon intersect(Contour inputContourA, Contour inputContourB)
{
    return intersect(
        polygon([inputContourA]),
        polygon([inputContourB])
    );
}

Polygon difference(Polygon inputPolyA, Polygon inputPolyB)
{
    return clip(gpc_op.GPC_DIFF, inputPolyA, inputPolyB);
}

Polygon difference(Contour inputContourA, Contour inputContourB)
{
    return difference(
        polygon([inputContourA]),
        polygon([inputContourB])
    );
}

Polygon exclusiveOr(Polygon inputPolyA, Polygon inputPolyB)
{
    return clip(gpc_op.GPC_XOR, inputPolyA, inputPolyB);
}

Polygon exclusiveOr(Contour inputContourA, Contour inputContourB)
{
    return exclusiveOr(
        polygon([inputContourA]),
        polygon([inputContourB])
    );
}

private:

Polygon clip(gpc_op operation, ref Polygon inputPolyA, ref Polygon inputPolyB)
{
    gpc_polygon polyA = gpcPolygon(inputPolyA);
    gpc_polygon polyB = gpcPolygon(inputPolyB);
    gpc_polygon result;

    gpc_polygon_clip(operation, &polyA, &polyB, &result);

    auto resultContoursVLists = result.contour[0 .. result.num_contours];

    auto merged = polygon(
        resultContoursVLists.map!((vList) {
            return contour(
                vList.vertex[0 .. vList.num_vertices].map!((vert) {
                    return vec2d(vert.x, vert.y);
                })()
            );
        })()
    );

    gpc_free_polygon(&polyA);
    gpc_free_polygon(&polyB);
    gpc_free_polygon(&result);

    return merged;
}

/++ Simple merging test +/
unittest
{
    import std.algorithm;

    auto quad1 = polygon(
        vec2d(0.0, 0.0),
        vec2d(1.0, 0.0),
        vec2d(1.0, 0.5),
        vec2d(0.0, 0.5)
    );

    auto quad2 = polygon(
        vec2d(0.0, 0.5),
        vec2d(1.0, 0.5),
        vec2d(1.0, 1.0),
        vec2d(0.0, 1.0)
    );

    Polygon quad = merge(quad1, quad2);
    assert(quad.contours.length == 1);

    auto contourVerts = quad.contours[0].vertices;
    assert(contourVerts.canFind(vec2d(0.0, 0.0)));
    assert(contourVerts.canFind(vec2d(1.0, 0.0)));
    assert(contourVerts.canFind(vec2d(1.0, 1.0)));
    assert(contourVerts.canFind(vec2d(0.0, 1.0)));
}

/++ Simple intersection test +/
unittest
{
    import std.algorithm;

    auto quad1 = polygon(
        vec2d(0.0, 0.0),
        vec2d(2.0, 0.0),
        vec2d(2.0, 2.0),
        vec2d(0.0, 2.0)
    );

    auto quad2 = polygon(
        vec2d(1.0, 1.0),
        vec2d(3.0, 1.0),
        vec2d(3.0, 3.0),
        vec2d(1.0, 3.0)
    );

    auto intersectionContours = intersect(quad1, quad2).contours;

    assert(intersectionContours.length == 1);

    auto verts = intersectionContours[0].vertices;
    assert(verts.canFind(vec2d(1.0, 1.0)));
    assert(verts.canFind(vec2d(2.0, 1.0)));
    assert(verts.canFind(vec2d(2.0, 2.0)));
    assert(verts.canFind(vec2d(1.0, 2.0)));
}

/++ Simple difference test +/
unittest
{
    import std.algorithm;

    auto quad1 = polygon(
        vec2d(0.0, 0.0),
        vec2d(2.0, 0.0),
        vec2d(2.0, 2.0),
        vec2d(0.0, 2.0)
    );

    auto quad2 = polygon(
        vec2d(1.0, 1.0),
        vec2d(3.0, 1.0),
        vec2d(3.0, 3.0),
        vec2d(1.0, 3.0)
    );

    auto differenceContours = difference(quad1, quad2).contours;

    assert(differenceContours.length == 1);

    auto verts = differenceContours[0].vertices;

    assert(verts.canFind(vec2d(0.0, 0.0)));
    assert(verts.canFind(vec2d(2.0, 0.0)));
    assert(verts.canFind(vec2d(0.0, 2.0)));

    assert(verts.canFind(vec2d(1.0, 1.0)));
    assert(!verts.canFind(vec2d(2.0, 2.0)));
}

/++ Hole making difference test +/
unittest
{
    import std.algorithm;

    auto quad1 = polygon(
        vec2d(0.0, 0.0),
        vec2d(1.0, 0.0),
        vec2d(1.0, 1.0),
        vec2d(0.0, 1.0)
    );

    auto quad2 = polygon(
        vec2d(0.4, 0.4),
        vec2d(0.6, 0.4),
        vec2d(0.6, 0.6),
        vec2d(0.4, 0.6)
    );

    auto differenceContours = difference(quad1, quad2).contours;

    assert(differenceContours.length == 2);

    auto outerVerts = differenceContours[1].vertices;
    assert(outerVerts.canFind(vec2d(0.0, 0.0)));
    assert(outerVerts.canFind(vec2d(1.0, 0.0)));
    assert(outerVerts.canFind(vec2d(1.0, 1.0)));
    assert(outerVerts.canFind(vec2d(0.0, 1.0)));

    auto innerVerts = differenceContours[0].vertices;
    assert(innerVerts.canFind(vec2d(0.4, 0.4)));
    assert(innerVerts.canFind(vec2d(0.6, 0.4)));
    assert(innerVerts.canFind(vec2d(0.6, 0.6)));
    assert(innerVerts.canFind(vec2d(0.4, 0.6)));
}
