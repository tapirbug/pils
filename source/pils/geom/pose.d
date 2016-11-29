module pils.geom.pose;

public
{
    import pils.geom.typecons;
}

private
{
    import painlessjson;
    import std.conv : to;
}

struct Pose(size_t dim)
{
    static assert(dim >= 2 && dim <= 3);

    mixin DimensionProperties!("position", dim);
    mixin DimensionProperties!("scale", dim);

    static if(dim == 2)
    {
        // Here orientation is a one float representing the angle, no accessors needed
        float orientation;
        @SerializeIgnore vec2d position = vec2d(0.0, 0.0);
        @SerializeIgnore vec2d scale = vec2d(1.0, 1.0);
    }
    else static if(dim == 3)
    {
        @SerializeIgnore vec3d position = vec3d(0.0, 0.0, 0.0);
        @SerializeIgnore vec3d scale = vec3d(1.0, 1.0, 1.0);

        @SerializeIgnore quatd orientation = quatd.identity;
        mixin DimensionProperties!("orientation", 4);
    }
    else
    {
        @SerializeIgnore Vector!(double, dim) position;
        @SerializeIgnore Vector!(double, dim) scale;
    }
}

unittest
{
    auto poseJson = `
    {
        "orientationX": 0.1,
        "orientationY": 0.2,
        "orientationZ": 0.3,
        "orientationW": 0.4,
        "scaleX": 0.5,
        "scaleY": 0.6,
        "scaleZ": 0.7,
        "positionX": 0.8,
        "positionY": 0.9,
        "positionZ": 1.0
    }
    `;

    import std.json;
    auto pose = poseJson.parseJSON()
                        .fromJSON!(Pose!3)();

    assert(pose.orientation == quatd(0.4, 0.1, 0.2, 0.3));
    assert(pose.scale == vec3d(0.5, 0.6, 0.7));
    assert(pose.position == vec3d(0.8, 0.9, 1.0));
}

private:

mixin template DimensionProperties(string targetProperty, size_t dim)
{
    static assert(dim >= 1 && dim <= 4);

    static if(dim >= 1)
    {
        mixin(generateDimensionAccessor!(targetProperty, 0));
        mixin(generateDimensionWriter!(targetProperty, 0));
    }

    static if(dim >= 2)
    {
        mixin(generateDimensionAccessor!(targetProperty, 1));
        mixin(generateDimensionWriter!(targetProperty, 1));
    }

    static if(dim >= 3)
    {
        mixin(generateDimensionAccessor!(targetProperty, 2));
        mixin(generateDimensionWriter!(targetProperty, 2));
    }

    static if(dim >= 4)
    {
        mixin(generateDimensionAccessor!(targetProperty, 3));
        mixin(generateDimensionWriter!(targetProperty, 3));
    }
}

enum dimensionSuffixes = [ "X", "Y", "Z", "W" ];
enum dimensionSuffixesDotLC = [ ".x", ".y", ".z", ".w" ];

template generateDimensionAccessor(string targetProperty, size_t dimIdx)
{
    static assert(dimIdx >= 0 && dimIdx < 4);

    enum dimensionPropName = targetProperty ~ dimensionSuffixes[dimIdx];

    enum generateDimensionAccessor = "@SerializedName(\"" ~ dimensionPropName ~ "\") @property public " ~
                                     "double " ~ dimensionPropName ~ "()" ~
                                     "{" ~
                                     "return " ~ targetProperty ~ dimensionSuffixesDotLC[dimIdx] ~ ";" ~
                                     "}";
}

template generateDimensionWriter(string targetProperty, size_t dimIdx)
{
    static assert(dimIdx >= 0 && dimIdx < 4);

    enum dimensionPropName = targetProperty ~ dimensionSuffixes[dimIdx];

    enum generateDimensionWriter = "@SerializedName(\"" ~ dimensionPropName ~ "\") @property public " ~
                                   "void " ~ dimensionPropName ~ "(double val)" ~
                                   "{" ~
                                   targetProperty ~ dimensionSuffixesDotLC[dimIdx] ~ " = val;" ~
                                   "}";
}
