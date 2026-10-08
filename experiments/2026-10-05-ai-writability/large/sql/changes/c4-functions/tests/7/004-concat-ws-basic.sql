-- concat_ws puts the separator between the arguments after it
SELECT concat_ws(', ', 'red', 'green', 'blue');
SELECT concat_ws('-', 2026, 10, 8);
SELECT concat_ws('', 'a', 'b', 'c');
SELECT concat_ws('/', 'solo');
SELECT concat_ws(0, 1, 2, 3), concat_ws(0.5, 'x', 'y');
SELECT typeof(concat_ws(':', 1, 2));
