-- concat_ws: two or more arguments
SELECT concat_ws('x');
SELECT CONCAT_WS();
SELECT concat_ws(NULL);
SELECT concat_ws(NULL, NULL);
SELECT concat_ws('.', 'a', 'b', 'c', 'd', 'e');
