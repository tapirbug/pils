module pils.solver;

private
{
    import pils.layout;
    import pils.geom.sets;
    import pils.geom.tesselate;
    import pils.geom.dump;
    import pils.geom.minkowski;
    import pils.entity.catalog;

    import std.stdio;
    import std.random;
    import std.array;
    import std.exception : enforce;
    import std.algorithm.searching : canFind;
    import std.algorithm.iteration : map, joiner, filter;
    import std.random;
}

/++
 + Provides the core placement logic that applies constraints to find possible
 + locations of an object and randomly choosing one of those.
 +/
class Solver
{
    /++
     + Creates a new solver with the given starting layout.
     +/
    this(Layout layout)
    {
        this.layout = layout;
    }

    Polygon transformPoly(Polygon source, Pose pose)
    {
        source = source.dup;

        foreach(ref contour; source.contours)
        {
            auto orientationMat = cast(mat4d) pose.orientation;

            contour.vertices = contour.vertices.map!((v) => v + pose.position.xz).array;

            //vec3d position = orientationMat * vec4d(pose.position, 1.0);
            //vec3d position = pose.position

            //contour.vertices = contour.vertices.map!((v) => )
        }

        return source;
    }

    bool cannotOverlap(Feature f1, Feature f2)
    {
        return f1.tags.canFind("OffLimits") && f2.tags.canFind("OffLimits");
    }

    void place(EntityPrototype proto, string groundTag)
    {
        auto groundFeatures = layout.findFeaturesByTag(groundTag);

        enforce(!groundFeatures.empty, "Ground feature " ~ groundTag ~ " could not be found");

        auto firstGroundFeature = groundFeatures.front;

        auto possibleLocations = firstGroundFeature.polygon;
        auto possibleLocationsPose = firstGroundFeature.pose;

        possibleLocations = transformPoly(possibleLocations, possibleLocationsPose);

        foreach(protoFeature; proto.features)
        {
            foreach(layoutEnt; layout.entities)
            {
                foreach(layoutFeature; layoutEnt.features)
                {
                    if(cannotOverlap(protoFeature, layoutFeature))
                    {
                        auto protoFeaturePoly = transformPoly(protoFeature.polygon, protoFeature.pose);
                        auto layoutFeaturePoly = transformPoly(transformPoly(layoutFeature.polygon, layoutFeature.pose), layoutEnt.pose);
                        auto layoutFeatureImpossible = minkowskiSum(layoutFeaturePoly, protoFeaturePoly);
                        //writeln("Proto: ", protoFeaturePoly);
                        //writeln("Possible before: ", possibleLocations);
                        //writeln("Layout: ", layoutFeaturePoly);

                        // TODO subtract MinkowksiSum not just layoutFeaturePoly
                        possibleLocations = possibleLocations.difference(layoutFeatureImpossible);
                        // possibleLocations.dump(possibleLocationsPose, "debug", "possible contours");

                        //writeln("Still possible locations: ", possibleLocations);
                        //writeln();
                    }
                }
            }
        }

        // TODO object rules

        if(!possibleLocations.contours.empty)
        {
            debug {
                //possibleLocations.dump(possibleLocationsPose, "debug", "possible contours");
            }

            auto allTriangles = possibleLocations.triangles.array;
            auto allAreas     = allTriangles.map!((t) => t.area)();
            auto anyTriangleIndex = dice(allAreas);

            auto anyTriangle = allTriangles[anyTriangleIndex];

            auto anyTriangleCenter = (anyTriangle.a + anyTriangle.b + anyTriangle.c) / 3;

            auto ent = proto.instantiate(vec3d(anyTriangleCenter.x, possibleLocationsPose.position.z, anyTriangleCenter.y), possibleLocationsPose.orientation);
            layout ~= ent;
        }



        /*if(!strips.empty && !strips[0].empty)
        {
            vec2d somePoint = strips[0][uniform(0, strips[0].length)];

            auto ent = proto.instantiate(vec3d(somePoint.x, 0.0, somePoint.y));
            layout ~= ent;
        }*/
    }

private:
    Layout layout;
}
