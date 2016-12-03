module pils.entity;

public
{
    import pils.geom.typecons;
    import pils.feature;
}

private
{
    import std.typecons : Proxy;
    import std.algorithm.searching : canFind, find;
    import std.algorithm.iteration : filter, map;
    import std.array;
    import std.exception;
    import std.file;
    import std.path;
    import std.json : parseJSON;
    import painlessjson;
    import pils.geom.pose;
}

class EntityLibrary
{
public:
    EntityPrototype[] protoypes;

    EntityPrototype findByID(string id)
    {
        auto result = protoypes.find!((p) => p.meta.id == id)();
        return result.empty ? null : result.front;
    }

    this(string basePath)
    {
        enforce(isDir(basePath), "Library base path must be a directory");
        loadFrom(basePath);
    }


private:

    void loadFrom(string basePath)
    {
        bool isProtoypeDir(string dir)
        {
            if(!isDir(dir))
            {
                return false;
            }

            auto dirname = baseName(dir);
            auto contentFiles = dir.dirEntries(SpanMode.shallow)
                                   .filter!isFile()
                                   .map!baseName();

            return contentFiles.canFind(dirname ~ ".json");
        }

        EntityPrototype dirToPrototype(string dir)
        {
            auto dirname = baseName(dir);
            string dataFilePath = chainPath(dir, dirname ~ ".json").array;

            EntityPrototype proto = dataFilePath.readText()
                                                .parseJSON()
                                                .fromJSON!EntityPrototype();


            foreach(ref pl; proto.placements)
            {
                pl.mesh = chainPath(dir, pl.mesh).array.absolutePath();
            }

            return proto;

        }

        protoypes = basePath.dirEntries(SpanMode.shallow)
                            .filter!isProtoypeDir()
                            .map!dirToPrototype().array;
    }
}

unittest
{
    import std.stdio;

    // a relative path should not throw
    auto lib = new EntityLibrary("examples/classlibs/krachzack");


}

class EntityPrototype
{
public:
    EntityMeta meta;
    EntityPlacement[] placements;
    Feature[] features;

    Entity instantiate(vec3d position, vec3d scale=vec3d(1.0, 1.0, 1.0), quatd orientation=quatd.identity)
    {
        return new Entity(meta, placements, features, position, scale, orientation);
    }
}

class Entity
{
public:
    EntityMeta meta;
    EntityPlacement[] placements;
    Feature[] features;
    Pose pose;

private:
    this(EntityMeta meta, EntityPlacement[] placements, Feature[] features, vec3d position, vec3d scale, quatd orientation)
    {
        this.meta = meta;
        this.placements = placements;
        this.features = features;
        this.pose.position = position;
        this.pose.scale = scale;
        this.pose.orientation = orientation;
    }
}

class EntityMeta
{
    string id;
    string name;
    string description;
    string[] tags;
    string[] authors;
    string directory;
}

struct EntityPlacement
{
    string name;
    string mesh;
    Pose pose;
}
