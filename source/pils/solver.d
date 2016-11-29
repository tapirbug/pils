module pils.solver;

private
{
    import pils.layout;
    import pils.entity;
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

    void place(Entity newEnt)
    {
        //auto groundFeatures = layout.findFeaturesByTag(newEnt.groundTag);
    }

private:
    Layout layout;
}
