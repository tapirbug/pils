module pils.entity.blueprint;

public
{
    import pils.geom.typecons;
    import pils.entity.types;
}

class EntityPrototype
{
public:
    EntityMeta meta;
    EntityPlacement[] placements;
    Feature[] features;

    Entity instantiate(vec3d position, quatd orientation=quatd.identity, vec3d scale=vec3d(1.0, 1.0, 1.0))
    {
        return new Entity(meta, placements, features, position, scale, orientation);
    }
}
