-- concat_ws: separator text forms, between consecutive values only
SELECT concat_ws(' | ', 'a', 'b');
SELECT concat_ws(10, 1, 2), concat_ws(1.0, 'p', 'q');
SELECT concat_ws('::', 'only one');
SELECT concat_ws('', NULL, 'x', NULL, 'y');
SELECT concat_ws(',', 1.5, -2, 'z');
