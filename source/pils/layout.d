module pils.layout;

private
{
    import pils.entity;
    import pils.feature;
    import pils.geom.typecons;
    import painlessjson;
}

class Layout
{
public:
    @property Entity[] entities()
    {
        auto lib = new EntityLibrary("examples/classlibs/krachzack");

        EntityPrototype tofteryd = lib.findByID("krachzack.tofteryd");
        Entity[] ents = [
            tofteryd.instantiate(vec3d(-0.5, 0, 1), vec3d(1, 1, 1), quatd.identity()),
            tofteryd.instantiate(vec3d(1, 0, 1), vec3d(1, 1, 1), quatd.identity())
        ];

        writeln(ents.toJSON.toString);

        return ents;
    }

    @property string json()
    {
        return entities.toJSON.toString;
    }

    Feature[] findFeaturesByTag(string tag)
    {
        assert(false);
    }
}
