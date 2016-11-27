module pils.entity;

public
{
    import pils.geom.typecons;
}

private
{
    import painlessjson;
}

class Entity
{
public:
    string className;
    string groundTag;
    string model;
    @SerializeIgnore vec3d position;
    @SerializeIgnore vec3d scale;
    @SerializeIgnore quatd orientation;

    this(string className, string model, vec3d position, vec3d scale, quatd orientation)
    {
        this.className = className;
        this.model = model;
        this.position = position;
        this.scale = scale;
        this.orientation = orientation;
    }

    @SerializedName("position")
    @property const double[3] positionArray() { return position.v; }
    @SerializedName("position")
    @property void positionArray(double[3] newPos) { position.v = newPos; }

    @SerializedName("scale")
    @property const double[3] scaleArray() { return scale.v; }
    @SerializedName("scale")
    @property void scaleArray(double[3] newScale) { scale.v = newScale; }

    /++
     + Gets the orientation of this element as a static-length double array of
     + eulerian angles. The order is XYZ or more formally, roll, pitch, yaw.
     + Yaw is defined as the rotation around the X axis, pitch around the Y axis
     + and roll around the z axis. This is compatible to the default setting in
     + blender which is XYZ a.k.a roll, pitch, yaw.
     +/
    @SerializedName("orientation")
    @property const double[3] orientationEulersArray()
    {
        return orientation.toEulerAngles().v;
    }

    /++
     + Sets the orientation of this element with an array of three euler angles.
     + The order is XYZ or more formally, roll, pitch, yaw.
     + Yaw is defined as the rotation around the X axis, pitch around the Y axis
     + and roll around the z axis. This is compatible to the default setting in
     + blender which is XYZ a.k.a roll, pitch, yaw.
     +/
    @SerializedName("orientation")
    @property void orientationEulersArray(double[] newScale)
    {
        orientation = quatd.fromEulerAngles(newScale[0], newScale[1], newScale[2]);
    }
}
