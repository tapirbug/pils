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

auto transform(Pose pose, vec3d vtx)
{
    vtx = pose.orientation.transform(vtx);
    vtx *= pose.scale;
    vtx += pose.position;

    return vtx;
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
