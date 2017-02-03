module pils.solving.layout;

public
{
    import pils.entity;
}

private
{
    import pils.geom.types;
    import std.algorithm.searching : any, canFind;
    import std.algorithm.iteration : map, filter, joiner;
    import std.range.primitives : isForwardRange, ElementType;
    import std.traits : isSomeString;
    import painlessjson;
}

class Layout
{
public:
    Entity[] entities;

    void clear()
    {
        entities.length = 0;
    }

    @property auto features()
    {
        return entities.map!((e) => e.features)().joiner();
    }

    @property string json()
    {
        return entities.toJSON.toString;
    }

    auto findFeaturesByTag(string tag)
    {
        return features.filter!((f) => f.tags.canFind(tag));
    }

    auto findFeaturesByTags(T)(T tagRange) if(isForwardRange!T && isSomeString!(ElementType!T))
    {
        return features.filter!((f) => tagRange.any!((tag) => f.tags.canFind(tag)));
    }

    void opOpAssign(string op)(Entity newEntity) if(op == "~")
    {
        entities ~= newEntity;
    }
}
