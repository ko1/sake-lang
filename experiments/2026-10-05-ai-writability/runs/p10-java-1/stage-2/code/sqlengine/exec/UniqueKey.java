package sqlengine.exec;

/** A UNIQUE or (non-rowid) PRIMARY KEY constraint over the columns at these indexes, in declared order. */
record UniqueKey(int[] columns) { }
