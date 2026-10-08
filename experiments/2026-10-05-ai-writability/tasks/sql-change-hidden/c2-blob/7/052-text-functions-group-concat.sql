CREATE TABLE parts (id INTEGER, grp TEXT, p BLOB);
INSERT INTO parts VALUES (1, 'a', X'6F6E65'), (2, 'a', X'74776F'), (3, 'b', X'78'), (4, 'b', NULL);
SELECT grp, group_concat(p, '+' ORDER BY id), typeof(group_concat(p)) FROM parts GROUP BY grp ORDER BY grp;
SELECT group_concat(p, X'2C' ORDER BY id DESC) FROM parts;
