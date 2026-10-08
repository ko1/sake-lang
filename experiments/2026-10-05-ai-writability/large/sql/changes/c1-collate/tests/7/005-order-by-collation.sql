-- ORDER BY sorts under the term's collation, or the result column's for a number or an alias.
CREATE TABLE fruit (id INTEGER, name TEXT COLLATE NOCASE, label TEXT);
INSERT INTO fruit VALUES (1, 'banana', 'banana'), (2, 'Apple', 'Apple'), (3, 'cherry', 'cherry'),
  (4, 'apple', 'apple'), (5, '_kiwi', '_kiwi'), (6, 'Date', 'Date'), (7, NULL, NULL);
SELECT id, name FROM fruit ORDER BY name, id;
SELECT id, label FROM fruit ORDER BY label, id;
SELECT id FROM fruit ORDER BY label COLLATE NOCASE DESC, id;
SELECT id, name FROM fruit ORDER BY name COLLATE BINARY, id;
SELECT label AS l, id FROM fruit ORDER BY l COLLATE NOCASE, 2;
SELECT name, id FROM fruit ORDER BY 1 DESC, 2;
SELECT group_concat(label, ',' ORDER BY label COLLATE NOCASE, id) FROM fruit;
