-- scenario: a school's classes; the schema grows while reports keep working
CREATE TABLE pupil (id INTEGER PRIMARY KEY, name TEXT NOT NULL, form TEXT);
CREATE TABLE club (pupil_id INTEGER, club TEXT);
INSERT INTO pupil (name, form) VALUES ('amy', '1a'), ('bo', '1a'), ('cai', '1b'), ('dot', '1b'), ('eli', '2a');
INSERT INTO club VALUES (1, 'chess'), (1, 'choir'), (3, 'chess'), (4, 'drama'), (5, 'choir');
CREATE INDEX club_pupil ON club (pupil_id);
CREATE UNIQUE INDEX club_once ON club (pupil_id, club);
INSERT INTO club VALUES (3, 'chess');
SELECT p.name FROM pupil p WHERE p.id NOT IN (SELECT pupil_id FROM club) ORDER BY p.name;
SELECT form, count(*) FROM pupil GROUP BY form UNION ALL SELECT 'clubs', count(DISTINCT club) FROM club ORDER BY 1;
WITH members AS (SELECT p.form, c.club FROM pupil p JOIN club c ON c.pupil_id = p.id)
SELECT club FROM members WHERE form = '1a' INTERSECT SELECT club FROM members WHERE form = '1b';
ALTER TABLE pupil ADD COLUMN house TEXT DEFAULT 'red';
UPDATE pupil SET house = 'blue' WHERE id % 2 = 0;
SELECT house, group_concat(name, ',' ORDER BY name) FROM pupil GROUP BY house ORDER BY house;
ALTER TABLE club RENAME COLUMN club TO activity;
INSERT INTO club VALUES (1, 'chess');
INSERT INTO club (pupil_id, activity) SELECT id, 'sport' FROM pupil WHERE house = 'blue';
SELECT activity, count(*) FROM club GROUP BY activity ORDER BY count(*) DESC, activity;
CREATE VIEW roster AS SELECT p.name, p.house, c.activity FROM pupil p LEFT JOIN club c ON c.pupil_id = p.id;
SELECT name, house, activity FROM roster WHERE activity IS NULL OR activity = 'sport' ORDER BY name;
CREATE VIEW roster AS SELECT 1 AS x;
CREATE TABLE roster (x INTEGER);
SELECT name FROM roster WHERE house = 'red' EXCEPT SELECT name FROM roster WHERE activity = 'choir' ORDER BY name;
DROP VIEW roster;
DROP INDEX club_once;
DROP INDEX club_pupil;
INSERT INTO club VALUES (1, 'chess');
SELECT count(*) FROM club WHERE pupil_id = 1 AND activity = 'chess';
