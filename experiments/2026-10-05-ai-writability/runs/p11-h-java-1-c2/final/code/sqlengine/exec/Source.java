package sqlengine.exec;

import java.util.List;

/** One source of a FROM: name is null for an unnamed ( select ); offset is where its columns start in a row. */
record Source(String name, List<Column> columns, int offset) { }
