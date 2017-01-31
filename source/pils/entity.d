module pils.entity;

public
{
    import pils.geom.typecons;
    import pils.feature;
}

private
{
    import std.typecons : Proxy;
    import std.algorithm.searching : canFind, find, any;
    import std.algorithm.iteration : filter, map;
    import std.array;
    import std.exception;
    import std.file;
    import std.path;
    import std.json : parseJSON;
    import std.string : format;
    import painlessjson;
    import pils.geom.pose;
}

enum ENTITY_LIBRARY_PATH_GLOBAL = "/etc/lager/classlibs";

class EntityLibrary
{
public:
    EntityPrototype[] protoypes;

    EntityPrototype findByID(string id)
    {
        auto result = protoypes.find!((p) => p.meta.id == id)();
        return result.empty ? null : result.front;
    }

    this(string libId)
    {
        protoypes = loadEntityLibrary(libId);
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

    Entity instantiate(vec3d position, quatd orientation=quatd.identity, vec3d scale=vec3d(1.0, 1.0, 1.0))
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

private:

EntityPrototype[] loadEntityLibrary(string libId)
{
    /++
     + Checks if the given directory can be converted to an entityprotoype.
     +
     + This can be done when a json file with the same name as the directory is
     + contained.
     +/
    bool isProtoypeDir(string dir)
    {
        if(!exists(dir) || !isDir(dir))
        {
            return false;
        }

        auto dirname = baseName(dir);
        auto contentFiles = dir.dirEntries(SpanMode.shallow)
                               .filter!isFile()
                               .map!baseName();

        return contentFiles.canFind(dirname ~ ".json");
    }

    /++
     + Checks if a directory contains at least one protoype directory.
     +/
    bool isPrototypeLibrary(string dir)
    {
        return exists(dir) && isDir(dir) && dir.dirEntries(SpanMode.shallow).any!isProtoypeDir();
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

    /++
     + Returns an absolute path to the library denoted with the given id or null if
     + no such library was found.
     +/
    string resolveEntityLibraryFilepath(string libId)
    {
        string[] candiatePaths = [
            chainPath(getcwd(), libId).array,
            chainPath(ENTITY_LIBRARY_PATH_GLOBAL, libId).array
        ];

        auto searchResult = candiatePaths.find!isPrototypeLibrary();
        return searchResult.empty ? null : searchResult.front;
    }

    auto libraryBasePath = resolveEntityLibraryFilepath(libId);
    return libraryBasePath.dirEntries(SpanMode.shallow)
                          .filter!isProtoypeDir()
                          .map!dirToPrototype().array;
}
