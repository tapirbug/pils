/++
 + Contains types shared by the entity submodules and by users of it.
 +
 + The types don't do much on their own but get their capabilities from the other
 + entity submodules.
 +/
module pils.entity.types;

public
{
    import pils.geom.typecons;
    import pils.geom.util : contour;
    import pils.entity.feature;
    import painlessjson;
}

class Entity
{
public:
    EntityMeta meta;
    EntityPlacement[] placements;
    Feature[] features;
    Pose pose;

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

struct Feature
{
    @SerializeIgnore Polygon polygon;
    string name;
    string[] tags;
    Pose pose;

    @SerializedName("vertices")
    @property double[][][] polygonVertices() {
        double[][][] polygonVertices;

        foreach(contour; polygon.contours)
        {
            double[][] contourVertices;

            foreach(vertex; contour.vertices)
            {
                contourVertices ~= vertex.v;
            }

            polygonVertices ~= contourVertices;
        }

        return polygonVertices;
    }
    @SerializedName("vertices")
    @property void polygonVertices(double[][][] polygonVertArr) {
        auto contours = polygonVertArr.map!contour();
        polygon = Polygon(contours.array);
    }

}
