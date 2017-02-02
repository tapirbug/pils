module pils.entity.catalog;

public
{
    import pils.geom.types;
    import pils.entity.types;
    import pils.entity.blueprint;
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
    import pils.geom.types;
}

class Catalog
{
public:
    Blueprint[] entries;

    Blueprint findByID(string id)
    {
        auto result = entries.find!((p) => p.meta.id == id)();
        return result.empty ? null : result.front;
    }

    /++
     + Constructs a new catalog from the given catalog symbol. The symbol may be
     + either the name of a global catalog in
     +/
    this(string catalogSymbol)
    {
        entries = loadCatalog(catalogSymbol);
    }
}

unittest
{
    // a relative path should not throw
    auto lib = new Catalog("examples/classlibs/krachzack");
}

private:

Blueprint[] loadCatalog(string catalogSymbol)
{
    /++
     + Checks if the given directory can be converted to a blueprint.
     +
     + This can be done when a json file with the same name as the directory is
     + contained.
     +/
    bool isBlueprintDir(string dir)
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
     + Checks if a directory contains at least one blueprint directory.
     +/
    bool isPrototypeLibrary(string dir)
    {
        return exists(dir) && isDir(dir) && dir.dirEntries(SpanMode.shallow).any!isBlueprintDir();
    }

    Blueprint dirToPrototype(string dir)
    {
        auto dirname = baseName(dir);
        string dataFilePath = chainPath(dir, dirname ~ ".json").array;

        Blueprint blueprint = dataFilePath.readText()
                                            .parseJSON()
                                            .fromJSON!Blueprint();


        foreach(ref pl; blueprint.placements)
        {
            pl.mesh = chainPath(dir, pl.mesh).array.absolutePath();
        }

        return blueprint;
    }

    /++
     + Gets the current users home directory on posix-like systems and C:/ on
     + windows.
     +/
    string home()
    {
        version(Windows)
        {
            // On Windows, we need to resolve an environment variable to obtain
            // the homedirectory equivalent, sine expandTilde per documentation,
            // does nothing on windows
            import std.process : environment;

            // Try to get USERPROFILE environment variable which should point
            // to the home folder equivalent on windows.
            auto profile = environment.get("USERPROFILE");

            //  If that does not work, assume C:\ as the home directory
            return (profile !is null) ? profile : "C:/";
        }
        else
        {
            // All other platforms probably support exapnding of tildes in pathnames
            return expandTilde("~");
        }
    }

    /++
     + Returns an absolute path to the library denoted with the given id or null if
     + no such library was found.
     +/
    string resolveCatalogFilepath(string catalogSymbol)
    {
        auto pathExecutable = buildNormalizedPath(dirName(thisExePath()), "../catalogs");
        auto pathSystem = "/etc/lager/catalogs";
        auto pathUser = buildPath(home(), ".config/lager/catalogs");
        auto pathWorkingDir = getcwd();

        // List of possible directories that might contain the catalog
        // The first hit is preferred if multiple match
        auto candiatePaths = [
            pathWorkingDir,
            pathUser,
            pathSystem,
            pathExecutable
        ].map!(p => buildPath(p, catalogSymbol));

        auto searchResult = candiatePaths.find!isPrototypeLibrary();
        return searchResult.empty ? null : searchResult.front;
    }

    auto libraryBasePath = resolveCatalogFilepath(catalogSymbol);
    return libraryBasePath.dirEntries(SpanMode.shallow)
                          .filter!isBlueprintDir()
                          .map!dirToPrototype().array;
}
