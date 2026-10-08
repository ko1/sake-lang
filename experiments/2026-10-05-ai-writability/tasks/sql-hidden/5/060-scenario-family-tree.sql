-- scenario: a family tree; ancestors, descendants and generations
CREATE TABLE person (id INTEGER PRIMARY KEY, name TEXT NOT NULL, born INTEGER);
CREATE TABLE parent (child INTEGER, par INTEGER, UNIQUE (child, par));
INSERT INTO person (name, born) VALUES ('gus', 1920), ('ida', 1925), ('ray', 1950), ('sue', 1952), ('tom', 1955), ('ana', 1980), ('ben', 1983), ('cal', 2010);
INSERT INTO parent VALUES (3, 1), (3, 2), (4, 1), (4, 2), (6, 3), (7, 4), (7, 5), (8, 6);
WITH RECURSIVE anc(id) AS (SELECT par FROM parent WHERE child = 8 UNION SELECT p.par FROM parent p JOIN anc ON p.child = anc.id)
SELECT pe.name FROM anc JOIN person pe ON pe.id = anc.id ORDER BY pe.born;
WITH RECURSIVE des(id, gen) AS (SELECT 1, 0 UNION ALL SELECT p.child, des.gen + 1 FROM parent p JOIN des ON p.par = des.id)
SELECT gen, count(*), group_concat(pe.name, ',' ORDER BY pe.name) FROM des JOIN person pe ON pe.id = des.id WHERE gen = 1 GROUP BY gen;
WITH RECURSIVE des(id, gen) AS (SELECT 1, 0 UNION ALL SELECT p.child, des.gen + 1 FROM parent p JOIN des ON p.par = des.id)
SELECT pe.name, max(gen) FROM des JOIN person pe ON pe.id = des.id GROUP BY pe.name ORDER BY max(gen), pe.name;
CREATE VIEW siblings AS SELECT DISTINCT a.child AS x, b.child AS y FROM parent a JOIN parent b ON a.par = b.par AND a.child <> b.child;
SELECT p1.name, p2.name FROM siblings s JOIN person p1 ON p1.id = s.x JOIN person p2 ON p2.id = s.y ORDER BY 1, 2;
SELECT name FROM person WHERE id NOT IN (SELECT child FROM parent) UNION SELECT 'nobody' WHERE 0 ORDER BY name;
INSERT INTO parent VALUES (6, 3);
INSERT INTO person (name, born) SELECT 'dee', born + 2 FROM person WHERE name = 'cal';
INSERT INTO parent SELECT max(id), 6 FROM person;
SELECT pe.name FROM parent p JOIN person pe ON pe.id = p.child WHERE p.par = 6 ORDER BY pe.born;
SELECT x, y FROM siblings WHERE x > 7 ORDER BY x, y;
ALTER TABLE person ADD COLUMN alive INTEGER DEFAULT 1;
UPDATE person SET alive = 0 WHERE born < 1930;
SELECT sum(alive), count(*) FROM person;
INSERT INTO siblings VALUES (1, 2);
DROP VIEW siblings;
