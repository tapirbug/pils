module pils.entity.blueprint;

public
{
    import pils.geom.types;
    import pils.entity.types;
}

class Blueprint
{
public:
    EntityMeta meta;
    EntityPlacement[] placements;
    Feature[] features;

    Entity build(vec3d position, quatd orientation=quatd.identity, vec3d scale=vec3d(1.0, 1.0, 1.0))
    {
        return new Entity(meta, placements, features, position, scale, orientation);
    }
}
