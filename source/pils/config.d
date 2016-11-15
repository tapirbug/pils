module pils.config;

import std.format;

enum pilsVersionMajor = 0;
enum pilsVersionMinor = 0;
enum pilsVersionPatch = 1;
enum pilsVersionAdditional = ".pre";

enum pilsVersion = format("%s.%s.%s%s",
                          pilsVersionMajor,
                          pilsVersionMinor,
                          pilsVersionPatch,
                          pilsVersionAdditional);
