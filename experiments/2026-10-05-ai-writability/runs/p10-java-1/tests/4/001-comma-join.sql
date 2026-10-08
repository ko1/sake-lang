-- A , B pairs every row of A with every row of B.
CREATE TABLE colors (name TEXT);
CREATE TABLE sizes (label TEXT, rank INTEGER);
INSERT INTO colors VALUES ('red'), ('blue');
INSERT INTO sizes VALUES ('S', 1), ('M', 2), ('L', 3);
SELECT name, label FROM colors, sizes ORDER BY name, rank;
SELECT count(*) FROM colors, sizes;
SELECT * FROM sizes, colors WHERE rank >= 2 ORDER BY rank DESC, name;
DELETE FROM colors;
SELECT count(*) FROM colors, sizes;
