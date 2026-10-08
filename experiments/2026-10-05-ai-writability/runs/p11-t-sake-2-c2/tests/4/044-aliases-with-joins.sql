-- Result column aliases are still found in WHERE and ORDER BY when sources are joined.
CREATE TABLE w (id INTEGER, base INTEGER);
CREATE TABLE f (id INTEGER, factor INTEGER);
INSERT INTO w VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO f VALUES (1, 3), (2, 1), (3, 2);
SELECT w.id, base * factor AS score FROM w JOIN f USING (id) WHERE score > 25 ORDER BY score;
SELECT w.id AS k, base FROM w JOIN f ON f.id = w.id ORDER BY k DESC;
SELECT base + factor AS s FROM w, f WHERE s = 22 ORDER BY s;
SELECT f.id AS base, w.base FROM w JOIN f ON w.id = f.id WHERE base > 15 ORDER BY w.id;
