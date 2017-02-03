module pils.geom.transform;

public
{
    import pils.geom.types;
}

private
{
    import std.conv : to;
    import std.exception : enforce;
    import std.algorithm.iteration;
    import std.array : array;
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

auto transform(Pose pose, vec3d vtx)
{
    vtx = pose.orientation.transform(vtx);
    vtx *= pose.scale;
    vtx += pose.position;
    return vtx;
}

unittest
{
    import std.math : PI;
    import pils.geom.util : almostEqual;

    Pose pose;
    pose.position = vec3d(-10, 100, -1000);
    pose.scale = vec3d(10, 10, 10);
    // Data from turning a by -90 at http://www.onlineconversion.com/quaternions.htm
    pose.orientation = quatd.fromAxis(vec3d(1,0,0), -PI/2).normalized;

    assert(almostEqual(pose.transform(vec3d(0, 0, 1)), pose.position + vec3d(0, 10, 0)));
    assert(almostEqual(pose.transform(vec3d(0, 1, 0)), pose.position + vec3d(0, 0, -10)));
    assert(almostEqual(pose.transform(vec3d(1, 0, 0)), pose.position + vec3d(10, 0, 0)));
}

auto transform(Pose pose, vec2d vertex)
{
    return pose.transform(vec3d(vertex, 0.0));
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
