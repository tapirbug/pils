module xyz.krachzack.cli;

import std.stdio;

import xyz.krachzack.config;

class Cli {
    void explain() {
        writefln("pils %s", pilsVersion);
        writefln("usage: pils [-s <seed>] config_file target_file");
    }
}

void main()
{
    Cli cli = new Cli();
    cli.explain();
}
