module pils.entity;

public
{
    import pils.geom.typecons;
    import pils.feature;
}

private
{
    import std.typecons : Proxy;
    import std.algorithm.searching : canFind;
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
    this(string basePath)
    {
        enforce(isDir(basePath));
        loadFrom(basePath);
    }


private:
    EntityPrototype[] protoypes;

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
            auto proto = new EntityPrototype();

            auto dirname = baseName(dir);
            string dataFilePath = chainPath(dir, dirname ~ ".json").array;

            import std.stdio;writeln("Prototype:\n", dataFilePath.readText()
                               .parseJSON()
                               .fromJSON!EntityPrototype().features);

            return dataFilePath.readText()
                               .parseJSON()
                               .fromJSON!EntityPrototype();
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

    Entity instantiate(vec3d position, vec3d scale, quatd orientation)
    {
        return new Entity(this, position, scale, orientation);
    }
}

class Entity
{
public:
    EntityPrototype prototype;
    mixin Proxy!prototype;
    Pose!3 pose;

private:
    this(EntityPrototype prototype, vec3d position, vec3d scale, quatd orientation)
    {
        this.prototype = prototype;
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
}

struct EntityPlacement
{
    string name;
    string mesh;

    Pose!3 pose;
}
