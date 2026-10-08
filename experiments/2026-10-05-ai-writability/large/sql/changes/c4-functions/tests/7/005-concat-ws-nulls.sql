-- concat_ws: NULL separator gives NULL; NULL values are skipped with their separator
SELECT concat_ws(NULL, 'a', 'b');
SELECT typeof(concat_ws(NULL, 'a'));
SELECT concat_ws(',', 'a', NULL, 'b');
SELECT concat_ws(',', NULL, 'b', NULL);
SELECT concat_ws(',', NULL, NULL), typeof(concat_ws(',', NULL));
SELECT concat_ws('+', NULL, 1, NULL, 2, NULL, 3);
