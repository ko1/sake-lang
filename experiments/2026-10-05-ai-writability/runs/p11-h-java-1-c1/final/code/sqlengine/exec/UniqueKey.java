package sqlengine.exec;

import sqlengine.value.Collation;

/** A UNIQUE or (non-rowid) PRIMARY KEY constraint over the columns at these indexes, in declared order, each compared under its collation (7.4). */
record UniqueKey(int[] columns, Collation[] collations) { }
