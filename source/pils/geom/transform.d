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
    import std.math : PI;
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
    return pose.orientation.inversed.normalized.transform(vtx);
}

unittest
{
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

/++
 + Constructs a new pose that applyies first and others in sequence.
 +/
Pose combine(P...)(P poses) if(poses.length >= 1 &&
                                 (
                                    isInputRange!(typeof(poses[0])) && is(ElementType!(typeof(poses[0])) == Pose))
                                    || is(typeof(poses[0]) == Pose
                                 )
                              )
{
    Pose combined = poses[0];

    static if(poses.length > 1)
    {
        foreach(pose; poses[1..$])
        {
            alias T = typeof(pose);

            static if(is(T == Pose))
            {
                combined.position += pose.position;
                combined.scale *= pose.scale;
                combined.orientation = (pose.orientation * combined.orientation).normalized;
            }
            else static if(isInputRange!T && is(ElementType!T == Pose))
            {
                // For ranges, recurse and let the above clause handle it
                foreach(Pose subPose; pose)
                {
                    combined = combine(combined, subPose);
                }
            }
            else
            {
                static assert(false, "Transform chain should only contain poses or ranges of poses");
            }
        }
    }

    return combined;
}

unittest
{
    import std.math : PI;
    import pils.geom.util : almostEqual;

    Pose x90;
    x90.orientation = quatd.fromAxis(vec3d(1, 0, 0), PI/2).normalized;

    assert(almostEqual(x90.transform(vec3d(0,0,1)), vec3d(0,-1,0)),
           "Rotating 90 degrees ccw around X axis should transform +Z to -Y");

    Pose x270 = combine(x90, x90, x90);
    assert(almostEqual(x270.transform(vec3d(0,0,1)), vec3d(0,1,0)),
           "Rotating 270 degrees ccw around X axis should transform +Z to +Y");
}

/++
 + Transforms the given vector from a OpenGL-like coordinate system with Y
 + pointing upwards and z pointing forward to a blender world point with Z
 + pointing upwards and Y pointing back.
 +/
@property vec3d blenderPoint(vec3d openGLSpacePoint)
{
     return quatd.fromAxis(vec3d(1, 0, 0), PI/2).normalized.transform(openGLSpacePoint);
    //return vec3d(openGLSpacePoint.x, -openGLSpacePoint.z, openGLSpacePoint.y);
}

/++
 + Flips the Z axis because that is the default setting in blender.
 +/
@property vec3d objPoint(vec3d openGLSpacePoint)
{
    openGLSpacePoint.z = -openGLSpacePoint.z;
    return openGLSpacePoint;
}
