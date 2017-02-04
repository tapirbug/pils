module pils.geom.dump;

public
{
    import pils.geom.types;
}

private
{
    import std.file : write;
    import std.path : chainPath, absolutePath;
    import std.string : format;
    import std.algorithm.iteration;
    import std.range : iota, chunks, chain, array;
    import std.datetime : Clock;
    import std.conv : to;
    import pils.geom.transform;
    import pils.geom.tesselate;
}

string toOBJ(Polygon poly, Pose pose)
{
    auto normal = pose.orientation.transform(vec3d(0.0, 0.0, 1.0));
    string normalLine = format("vn %#s %#s %#s\n", normal.x, normal.y, normal.z);

    // I need to array this so verts.length is available
    auto verts = poly.triangleVertices.map!(v => pose.transform(v))().array;

    alias makeVertexLine = vtx => format("v %#s %#s %#s\n", vtx.x, vtx.y, vtx.z);
    // Invert Z since that is the default setting in blender => map!objPoint()
    auto vertexLines = verts.map!objPoint().map!makeVertexLine();

    // For poor OBJ, indexing starts at 1
    auto indexes = iota(1u, 1u+verts.length).map!(to!string)();
    auto faceLines = indexes.chunks(3)
                            .map!(t => format("f %s//1 %s//1 %s//1\n", t[0], t[1], t[2]))();

    return to!string(chain(vertexLines.joiner, normalLine, faceLines.joiner));
}

void dump(Polygon poly, Pose pose, string outDirectory, string basename)
{
    auto filename = format("%s - %s.obj", Clock.currTime().toISOString(), basename);
    auto targetPath = chainPath(absolutePath(outDirectory), filename);
    string obj = poly.toOBJ(pose);
    targetPath.write(obj);
}
