CREATE TABLE crew (id INTEGER PRIMARY KEY, ship TEXT, name TEXT, rank INTEGER);
INSERT INTO crew (ship, name, rank) VALUES ('a', 'ray', 2), ('a', 'sue', NULL), ('b', 'tom', 1), ('a', 'uma', 1), ('b', 'vic', 3);
SELECT ship, group_concat(name, ' ' ORDER BY rank, name) FROM crew GROUP BY ship ORDER BY ship;
SELECT ship, group_concat(name, ' ' ORDER BY rank NULLS LAST) FROM crew GROUP BY ship ORDER BY ship;
SELECT group_concat(name ORDER BY rank DESC NULLS FIRST, id) FROM crew;
SELECT group_concat(name, '' ORDER BY length(name) - id) FROM crew WHERE ship = 'b';
SELECT group_concat(id, '.' ORDER BY 0 - id) FROM crew;
