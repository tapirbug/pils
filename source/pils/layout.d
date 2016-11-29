module pils.layout;

private
{
    import pils.entity;
    import pils.feature;
    import pils.geom.typecons;
    import painlessjson;
}

class Layout
{
public:
    @property Entity[] entities()
    {
        return [];
        version(none) {
            return [
                new Entity(
                    "IkeaChairFusion",
                    "/Users/phil/Dropbox/IM16/PRO1 libpils/Modelle/Sitzgruppe/IKEA_chair_FUSION/3cd4399871fb1a8768d1b9a1d97e2846_obj0_object.obj",
                    vec3d(5.0, 2.0, 0.0),
                    vec3d(0.01, 0.01, 0.01),
                    quatd.identity()
                ),
                new Entity(
                    "IkeaDeskLeksvik",
                    "/Users/phil/Dropbox/IM16/PRO1 libpils/Modelle/Tisch/Schreibtisch--IKEA_desk_LEKSVIK/e4265ddbf415ef1877fe0205d04e5011_obj0_object.obj",
                    vec3d(-5.0, 0.0, 0.0),
                    vec3d(0.01, 0.01, 0.01),
                    quatd.identity()
                )
            ];
        }
    }

    @property string json()
    {
        return entities.toJSON.toString;
    }

    Feature[] findFeaturesByTag(string tag)
    {
        assert(false);
    }
}
