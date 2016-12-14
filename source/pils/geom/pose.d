module pils.geom.pose;

public
{
    import pils.geom.typecons;
}

private
{
    import std.conv : to;
    import std.exception : enforce;
    import std.algorithm.iteration;
    import std.array : array;
    import std.json;
}

struct Pose
{
    vec3d position = vec3d(0.0, 0.0, 0.0);
    vec3d scale = vec3d(1.0, 1.0, 1.0);
    quatd orientation = quatd.identity;

    static Pose _fromJSON(JSONValue val)
    {
        double doublify(const(JSONValue) v)
        {
            if(v.type() == JSON_TYPE.INTEGER)
            {
                return cast(double) v.integer;
            }
            else if(v.type() == JSON_TYPE.FLOAT)
            {
                return cast(double) v.floating;
            }

            return double.nan;
        }

        Pose pose;

        if (const(JSONValue)* valPosition = "position" in val)
        {
            auto vals = valPosition.array;
            double[] arr = vals.map!doublify().array;
            enforce(arr.length == 3);
            pose.position = arr;
        }

        if (const(JSONValue)* valScale = "scale" in val)
        {
            auto vals = valScale.array;
            double[] arr = vals.map!doublify().array;
            enforce(arr.length == 3);
            pose.scale = arr;
        }

        if (const(JSONValue)* valOrientation = "orientation" in val)
        {
            auto vals = valOrientation.array;
            double[] arr = vals.map!doublify().array;
            enforce(arr.length == 4);

            pose.orientation.x = arr[0];
            pose.orientation.y = arr[1];
            pose.orientation.z = arr[2];
            pose.orientation.w = arr[3];
        }

        return pose;
    }

    const JSONValue _toJSON()
    {
        JSONValue[string] json;
        json["orientation"] = JSONValue(orientation.v.v);
        json["position"] = JSONValue(position.v);
        json["scale"] = JSONValue(scale.v);
        return JSONValue(json);
    }
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
