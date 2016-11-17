module pils.element;

public
{
    import gl3n.linalg;
    import pils.quat4d;
}

private
{
    import painlessjson;
}

class Element
{
public:
    string className;
    string model;
    @SerializeIgnore vec3d position;
    @SerializeIgnore vec3d scale;
    @SerializeIgnore quat4d orientation;

    @SerializedName("position")
    @property const double[3] positionArray() { return position.vector; }
    @SerializedName("position")
    @property void positionArray(double[3] newPos) { position.vector = newPos; }

    @SerializedName("scale")
    @property const double[3] scaleArray() { return scale.vector; }
    @SerializedName("scale")
    @property void scaleArray(double[3] newScale) { scale.vector = newScale; }

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
        with(orientation)
        {
            return [roll, pitch, yaw];
        }
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
        orientation = quat4d.euler_rotation(newScale[0], newScale[1], newScale[2]);
    }

    this(string className, string model, vec3d position, vec3d scale, quat4d orientation)
    {
        this.className = className;
        this.model = model;
        this.position = position;
        this.scale = scale;
        this.orientation = orientation;
    }
}
