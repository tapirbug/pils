module pils.geom.transform;

public
{
    import pils.geom.types;
}

private
{
    import pils.geom.cons;
    import std.conv : to;
    import std.exception : enforce;
    import std.algorithm.iteration;
    import std.array : array;
    import std.range.primitives;
}

/++
 + Applies the rotation in the given quaternion to the given vector and returns
 + the rotated vector.
 +
 + See_Also: https://blog.molecular-matters.com/2013/05/24/a-faster-quaternion-vector-multiplication/
 +
 +/
Vector!(T, 3u) transform(T)(Quaternion!T quat, Vector!(T, 3u) vec)
{
    auto q = quat.v;
    auto t = 2 * cross(q.xyz, vec);
    return vec + q.w * t + cross(q.xyz, t);
}

unittest
{
    import std.math : PI;
    import pils.geom.util : almostEqual;

    quatd identity = quatd.identity;

    assert(almostEqual(identity.transform(vec3d(1,0,0)), vec3d(1,0,0)),
           "multiplying with identity quaternion should change nothing");

    quatd x90 = quatd.fromAxis(vec3d(1, 0, 0), PI/2).normalized;
    assert(almostEqual(x90.transform(vec3d(0,0,1)), vec3d(0,-1,0)),
           "Rotating 90 degrees ccw around X axis should transform +Z to -Y");

    assert(almostEqual(x90.transform(vec3d(0,1,0)), vec3d(0,0,1)),
          "Rotating 90 degrees ccw around X axis should transform +Y to +Z");

    assert(almostEqual(x90.transform(vec3d(1,0,0)), vec3d(1,0,0)),
           "Rotating 90 degrees ccw around X axis should not change +X");
}

/++
 + Transforms from local space to world space
 +/
auto transform(Pose pose, vec3d vtx)
{
    vtx = pose.orientation.transform(vtx);
    vtx *= pose.scale;
    vtx += pose.position;
    return vtx;
}

auto untransform(Pose pose, vec3d vtx)
{
    vtx -= pose.position;
    vtx /= pose.scale;
    return pose.orientation.inversed.transform(vtx);
}

unittest
{
    import std.math : PI;
    import pils.geom.util : almostEqual;

    Pose pose;
    pose.position = vec3d(-10, 100, -1000);
    pose.scale = vec3d(10, 10, 10);
    pose.orientation = quatd.fromAxis(vec3d(1,0,0), -PI/2).normalized;

    assert(almostEqual(pose.transform(vec3d(0, 0, 1)), pose.position + vec3d(0, 10, 0)));
    assert(almostEqual(pose.transform(vec3d(0, 1, 0)), pose.position + vec3d(0, 0, -10)));
    assert(almostEqual(pose.transform(vec3d(1, 0, 0)), pose.position + vec3d(10, 0, 0)));

    assert(almostEqual(pose.untransform(pose.position + vec3d(0, 10, 0)), vec3d(0, 0, 1)));
    assert(almostEqual(pose.untransform(pose.position + vec3d(0, 0, -10)), vec3d(0, 1, 0)));
    assert(almostEqual(pose.untransform(pose.position + vec3d(10, 0, 0)), vec3d(1, 0, 0)));
}

auto transform(Pose pose, vec2d vertex)
{
    return pose.transform(vec3d(vertex, 0.0));
}

/++
 + Converts a vertex given within the coordinate system of source pose and
 + transforms it into the coordinate system of the target pose
 +/
auto convert(vec3d vertex, Pose sourcePose, Pose targetPose)
{
    return targetPose.untransform(
        sourcePose.transform(vertex)
    );
}

/++
 + Returns a range of vec3d-ranges, each representing one contour of the original
 + polygon transformed into 3D by first adding a Z component of zero and then
 + transforming the polygon using the given pose.
 +/
auto transform(Pose pose, Polygon original)
{
    return original.contours.map!((contour) {
        return contour.vertices.map!((vertex) {
            return pose.transform(vertex);
        })();
    })();
}

auto transform(P)(Pose pose, P polygonLike) if(isForwardRange!P && isForwardRange!(ElementType!P) && is(ElementType!(ElementType!P) == vec3d))
{
    return polygonLike.map!((contour) {
        return contour.map!((vertex) {
            return pose.transform(vertex);
        })();
    })();
}


/++
 + Given something that behaves like a range of contours with vectors of size
 + 3, returns a 2D polygon in local space of the given pose. The Z component
 + of the untrasformed polygon is thrown away
 +/
Polygon untransform(P)(Pose pose, P polygonLike) if(isForwardRange!P && isForwardRange!(ElementType!P) && is(ElementType!(ElementType!P) == vec3d))
{
    return polygon(
        polygonLike.map!((contourLike) {
            return contour(
                contourLike.map!((vec3d vtx) {
                    return pose.untransform(vtx).xy;
                })()
            );
        })()
    );
}

Polygon convert(Polygon poly, Pose sourcePose, Pose targetPose)
{
    auto worldPoly = sourcePose.transform(poly);
    return targetPose.untransform(worldPoly);
}
