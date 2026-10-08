package sqlengine.exec;

/** An index (5.7): it changes no result; a unique one owns a uniqueness constraint of its table. */
record IndexDef(String name, int[] columns, UniqueKey constraint) { }
