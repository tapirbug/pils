module pils.geom.basis;

public
{
    import pils.geom.types;
}

private
{
    import pils.geom.transform;
}

@property vec3d[3] orthonormalBasis(Pose pose)
{
    return [ pose.unitX, pose.unitY, pose.unitZ ];
}

@property vec3d unitX(Pose pose)
{
    return pose.orientation.transform(vec3d(1,0,0)).normalized;
}

@property vec3d unitY(Pose pose)
{
    return pose.orientation.transform(vec3d(0,1,0)).normalized;
}

@property vec3d unitZ(Pose pose)
{
    return pose.orientation.transform(vec3d(0,0,1)).normalized;
}

unittest
{
    import pils.geom.util : almostEqual;
    import std.math : PI;

    Pose pose;
    pose.position = vec3d(-10, 100, -1000);
    pose.scale = vec3d(10, 10, 10);
    pose.orientation = quatd.fromAxis(vec3d(1,0,0), -PI/2).normalized;

    // X points to the right from the perspective of a camera at 0,0,0 (almost)
    assert(almostEqual(pose.unitX, vec3d(1.0, 0.0, 0.0)));
    // Y points into the scene and forward from the camera (almost)
    assert(almostEqual(pose.unitY, vec3d(0.0, 0.0, -1.0)));
    // Z points upward (almost)
    assert(almostEqual(pose.unitZ, vec3d(0.0, 1.0, 0.0)));
}
