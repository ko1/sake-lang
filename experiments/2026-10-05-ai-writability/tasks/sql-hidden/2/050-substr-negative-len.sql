CREATE TABLE s (w TEXT, p INTEGER, q INTEGER);
INSERT INTO s VALUES ('planet', 4, -2), ('planet', -1, -3), ('planet', 0, -2), ('planet', 1, -1), ('planet', -7, 2), ('planet', -7, 3), ('planet', 8, -4);
SELECT p, q, '[' || substr(w, p, q) || ']' FROM s ORDER BY p, q;
SELECT substr('abc', -1, 1), substr('abc', -3, -1), substr('abc', 10), substr('abc', 4, -1);
