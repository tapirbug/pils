module pils.layout;

private
{
    import pils.element;
    import pils.quat4d;
    import painlessjson;
    import gl3n.linalg;
}

class Layout
{
public:
    @property Element[] elements()
    {
        return [
            new Element(
                "IkeaChairFusion",
                "/Users/phil/Dropbox/IM16/PRO1 libpils/Modelle/Sitzgruppe/IKEA_chair_FUSION/3cd4399871fb1a8768d1b9a1d97e2846_obj0_object.obj",
                vec3d(5.0, 2.0, 0.0),
                vec3d(0.01, 0.01, 0.01),
                quat4d.identity()
            ),
            new Element(
                "IkeaDeskLeksvik",
                "/Users/phil/Dropbox/IM16/PRO1 libpils/Modelle/Tisch/Schreibtisch--IKEA_desk_LEKSVIK/e4265ddbf415ef1877fe0205d04e5011_obj0_object.obj",
                vec3d(-5.0, 0.0, 0.0),
                vec3d(0.01, 0.01, 0.01),
                quat4d.identity()
            )
        ];
    }

    @property string json()
    {
        return elements.toJSON.toString;
    }
}
