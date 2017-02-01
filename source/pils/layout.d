module pils.layout;

public
{
    import pils.entity;
}

private
{
    import pils.geom.typecons;
    import std.algorithm.searching : canFind;
    import std.algorithm.iteration : map, filter, joiner;
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

    void opOpAssign(string op)(Entity newEntity) if(op == "~")
    {
        entities ~= newEntity;
    }
}
