module pils.layout;

private
{
    import std.algorithm.searching : canFind;
    import std.algorithm.iteration : map, filter, reduce, joiner;
    import std.range : chain;
    import pils.entity;
    import pils.feature;
    import pils.geom.typecons;
    import painlessjson;
}

class Layout
{
public:
    Entity[] entities;

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
