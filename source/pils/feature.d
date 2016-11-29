module pils.feature;

public
{
    import pils.geom.typecons;
    import pils.geom.pose;
}

private
{
    import std.algorithm : map;
    import std.array : array;

    import pils.geom.util;
    import painlessjson;
}

struct Feature
{
    @SerializeIgnore Polygon polygon;
    string name;
    string[] tags;
    Pose!3 pose;

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
