-- scenario: an org chart walked with recursive ctes
CREATE TABLE staff (id INTEGER PRIMARY KEY, name TEXT NOT NULL, boss INTEGER, salary INTEGER);
INSERT INTO staff VALUES (1, 'ceo', NULL, 300), (2, 'cto', 1, 200), (3, 'cfo', 1, 190);
INSERT INTO staff VALUES (4, 'dev1', 2, 120), (5, 'dev2', 2, 110), (6, 'acct', 3, 90), (7, 'intern', 4, 30);
WITH RECURSIVE chain(id, lvl) AS (SELECT id, 0 FROM staff WHERE boss IS NULL UNION ALL SELECT s.id, c.lvl + 1 FROM staff s JOIN chain c ON s.boss = c.id)
SELECT s.name, c.lvl FROM chain c JOIN staff s ON s.id = c.id ORDER BY c.lvl, s.name;
WITH RECURSIVE under(id) AS (SELECT id FROM staff WHERE name = 'cto' UNION ALL SELECT s.id FROM staff s JOIN under u ON s.boss = u.id)
SELECT count(*), sum(s.salary) FROM under u JOIN staff s ON s.id = u.id;
WITH RECURSIVE up(id, path) AS (SELECT boss, name FROM staff WHERE name = 'intern' UNION ALL SELECT s.boss, up.path || '<' || s.name FROM up JOIN staff s ON s.id = up.id)
SELECT path FROM up WHERE id IS NULL;
CREATE VIEW managers AS SELECT DISTINCT b.id, b.name FROM staff e JOIN staff b ON e.boss = b.id;
SELECT name FROM managers ORDER BY name;
SELECT name FROM staff EXCEPT SELECT name FROM managers ORDER BY name;
BEGIN;
UPDATE staff SET boss = 3 WHERE name = 'dev2';
INSERT INTO staff (name, boss, salary) VALUES ('dev3', 3, 100);
SELECT m.name, count(*) FROM staff e JOIN managers m ON e.boss = m.id GROUP BY m.name ORDER BY m.name;
ROLLBACK;
SELECT m.name, count(*) FROM staff e JOIN managers m ON e.boss = m.id GROUP BY m.name ORDER BY m.name;
SELECT max(id) FROM staff;
INSERT INTO staff (name, boss) SELECT 'temp' || id, id FROM staff WHERE id > 5 ORDER BY id;
SELECT id, name, boss FROM staff WHERE id > 7 ORDER BY id;
DROP VIEW managers;
SELECT name FROM managers;
