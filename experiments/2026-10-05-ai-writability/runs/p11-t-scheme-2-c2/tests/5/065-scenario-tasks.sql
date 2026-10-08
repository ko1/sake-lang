-- scenario: tasks with dependencies; a recursive cte finds what must be done first
CREATE TABLE task (id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL, hours INTEGER DEFAULT 1);
CREATE TABLE dep (task_id INTEGER, needs INTEGER, UNIQUE (task_id, needs));
INSERT INTO task (name, hours) VALUES ('design', 3), ('build', 8), ('test', 4), ('docs', 2), ('release', 1);
INSERT INTO dep VALUES (2, 1), (3, 2), (4, 1), (5, 3), (5, 4);
WITH RECURSIVE pre(id) AS (SELECT needs FROM dep WHERE task_id = 5 UNION SELECT d.needs FROM dep d JOIN pre p ON d.task_id = p.id)
SELECT t.name FROM pre p JOIN task t ON t.id = p.id ORDER BY t.id;
WITH RECURSIVE pre(id) AS (SELECT needs FROM dep WHERE task_id = 5 UNION SELECT d.needs FROM dep d JOIN pre p ON d.task_id = p.id)
SELECT sum(hours) FROM task WHERE id IN (SELECT id FROM pre);
WITH RECURSIVE depth(id, d) AS (SELECT id, 0 FROM task WHERE id NOT IN (SELECT task_id FROM dep) UNION ALL SELECT dep.task_id, depth.d + 1 FROM dep JOIN depth ON dep.needs = depth.id)
SELECT t.name, max(d) FROM depth JOIN task t ON t.id = depth.id GROUP BY t.name ORDER BY max(d), t.name;
CREATE VIEW ready AS SELECT name FROM task WHERE id NOT IN (SELECT task_id FROM dep);
SELECT name FROM ready;
DELETE FROM dep WHERE needs = 1;
SELECT name FROM ready ORDER BY name;
INSERT INTO dep VALUES (3, 2);
INSERT INTO task (name) VALUES ('review');
INSERT INTO task (name) VALUES ('Review');
SELECT id, name, hours FROM task WHERE id > 5 ORDER BY id;
INSERT INTO dep SELECT id, 3 FROM task WHERE name LIKE 'review';
SELECT task_id, needs FROM dep ORDER BY task_id, needs;
SELECT name FROM ready UNION SELECT name FROM task WHERE hours > 5 ORDER BY 1;
UPDATE ready SET name = 'x';
DROP TABLE ready;
