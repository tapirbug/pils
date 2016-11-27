module pils.planner;

public
{
    import pils.layout;
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
class Planner
{
public:
    // place X instances of class Y
    // place as many objects of class Z as possible
    // keep adding cupboards until the total amount of storage space exceeds 1.3 cubic meters
    // if context is “dinner” place 5 plates on a table in front of a chair and stack 10 plates in storage features, else stack 15 plates in storage features

    @property Layout layout() { return new Layout(); }
}
