/++
 + Contains types shared by all geometry modules and users of the module and
 + functionality to duplicate and compare the types.
 +
 + Also publicy imports for vectors, matrices, quaternions, and line segments.
 +/
module pils.geom.types;

public
{
    import gfm.math.vector;
    import gfm.math.quaternion;
    import gfm.math.matrix;
    import gfm.math.shapes; // Line segments, planes, etc.
}

private
{
    import std.algorithm.iteration : map;
    import std.algorithm.searching : canFind;
    import std.array : array;
    import std.range : cycle, take;
    import std.range.primitives;
    import std.json;
    import std.exception : enforce;
    import painlessjson;
}

/++
 + A polygon is a set of bounding contours of a domain.
 +/
struct Polygon
{
    Contour[] contours;

    @property auto dup() { return Polygon(contours.map!((d) => d.dup)().array); }
}

/++
 + Ordered set of edges represented in memory as an array of vertices.
 +
 + By itself, it contains functionality for checking for equality and
 + duplicating a contour. Additional functionality is added by the other
 + packages in `pils.geom`.
 +/
struct Contour
{
    vec2d[] vertices;

    /++
     + Checks whether the given other contour or vector range is equal to this
     + contour by checking whether it contains the same vertices with the same
     + winding order.
     +
     + It is not required that the contour represented by the parameter has the
     + same starting index as the called contour. Consider a contour other that
     + is offset by two vertices and starts at the third vertex of the called
     + contour. It is still considered equal if the winding order is the same.
     + Check out the unit tests for some examples of equal and unequal contours.
     +
     + Params:
     +         other = Other contour or range of vec2d with length property
     +                 defined to check for equality with this contour
     +/
    bool opEquals(S)(S other) if(is(S == Contour) || isForwardRange!S && hasLength!S && is(ElementType!S == vec2d))
    {
        static if(is(S == Contour)) {
            auto otherVerts = other.vertices;
        } else {
            auto otherVerts = other;
        }

        if(vertices.length != otherVerts.length) {
            return false;
        }

        return cycle(vertices).take(vertices.length*2 - 1).canFind(otherVerts);
    }

    unittest
    {
        import std.range : retro;

        // Same order, is equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)])
        );

        // Second contour is offset to start at the third element of the first,
        // still equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            Contour([vec2d(1.0, 1.0), vec2d(0.0, 0.0), vec2d(1.0, 0.0)])
        );

        // Second contour is offset to start at the second element of the first,
        // still equal, also using array instead of contour
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) ==
            [vec2d(1.0, 0.0), vec2d(1.0, 1.0), vec2d(0.0, 0.0)]
        );

        // Second contour has reversed winding order,
        // not equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) !=
            [vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)].retro
        );

        // Count is different, not equal
        assert(
            Contour([vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0)]) !=
            [vec2d(0.0, 0.0), vec2d(1.0, 0.0), vec2d(1.0, 1.0), vec2d(0.0, 0.0)]
        );
    }

    @property auto dup() { return Contour(vertices.dup); }
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
