module pils.planner;

public
{
    import pils.layout;
    import pils.solver;
    import pils.entity;
}

private
{

}

/++
 + Submits objects to the solver, which in turn places them one by one.
 + The Planner provides some higher level control, e.g. place 12 desks or
 + add wardrobes until there is 3 cubic meters of space for clothes.
 +
 + The Planner works by executing a number of rules in order.
 +/
 // place X instances of class Y
 // place as many objects of class Z as possible
 // keep adding cupboards until the total amount of storage space exceeds 1.3 cubic meters
 // if context is “dinner” place 5 plates on a table in front of a chair and stack 10 plates in storage features, else stack 15 plates in storage features
class Planner
{
public:
    Solver solver;
    EntityLibrary lib;
    Layout layout;

    this(EntityLibrary lib)
    {
        layout = new Layout();
        solver = new Solver(layout);
        this.lib = lib;
    }

    void planLivingroom()
    {
        // starting layout
        layout ~= lib.findByID("krachzack.loneroom").instantiate(vec3d(0,0,0));

        // place some tables
        EntityPrototype tofteryd = lib.findByID("krachzack.tofteryd");
        EntityPrototype mandal = lib.findByID("krachzack.mandal");

        solver.place(mandal, "Ground");

        foreach(i; 0..15) {
            solver.place(tofteryd, "Ground");
        }
    }

private:
}
