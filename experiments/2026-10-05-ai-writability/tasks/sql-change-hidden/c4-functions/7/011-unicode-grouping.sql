-- unicode in expressions, GROUP BY and ORDER BY
CREATE TABLE items (name TEXT);
INSERT INTO items VALUES ('bolt'), ('Bar'), ('axle'), ('bead'), ('Arm');
SELECT unicode(name) AS u, count(*) FROM items GROUP BY u ORDER BY u;
SELECT name FROM items ORDER BY unicode(name) DESC, name;
SELECT unicode(upper('k')) - unicode('k'), unicode(lower(name)) FROM items WHERE name = 'Arm';
