-- A comment line before the first statement.
SELECT 1; -- trailing comment
SELECT /* inline */ 2;
/* a comment
   over several lines; with a semicolon */
SELECT 3
  +
	4;
SELECT 5 -- comment inside a statement
  + 1;
SELECT '-' || /* between */ '-';
SELECT 6/**/;
/* the end */
