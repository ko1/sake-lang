-- A to-do app: projects, tasks and tags.
CREATE TABLE projects (pid INTEGER PRIMARY KEY, pname TEXT UNIQUE, owner TEXT);
CREATE TABLE tasks (id INTEGER PRIMARY KEY, pid INTEGER, title TEXT NOT NULL, done INTEGER DEFAULT 0, prio INTEGER);
CREATE TABLE tags (task_id INTEGER, tag TEXT, PRIMARY KEY (task_id, tag));
INSERT INTO projects (pname, owner) VALUES ('home', 'ann'), ('work', 'ann'), ('garden', 'bob'), ('trip', 'cy');
INSERT INTO tasks (pid, title, prio) VALUES (1, 'dishes', 2), (1, 'laundry', 1), (2, 'report', 3), (2, 'email', 1),
  (3, 'weed', 2), (2, 'slides', 3);
INSERT INTO tags VALUES (1, 'chore'), (2, 'chore'), (3, 'urgent'), (6, 'urgent'), (6, 'boss'), (5, 'outside');
UPDATE tasks SET done = 1 WHERE title IN ('dishes', 'email');
INSERT INTO tags VALUES (3, 'boss'), (6, 'urgent');
-- open tasks with their project, highest priority first
SELECT pname, title, prio FROM tasks JOIN projects USING (pid) WHERE NOT done ORDER BY prio DESC, title;
-- progress per project, empty projects included
SELECT pname, count(id), total(done), CASE WHEN count(id) = 0 THEN NULL ELSE sum(done) * 100 / count(id) END
  FROM projects LEFT JOIN tasks USING (pid) GROUP BY pid ORDER BY pid;
-- tags of each open task
SELECT title, (SELECT group_concat(tag, ',' ORDER BY tag) FROM tags WHERE task_id = tasks.id) FROM tasks
  WHERE done = 0 ORDER BY id;
-- tasks tagged both urgent and boss
SELECT title FROM tasks t WHERE EXISTS (SELECT 1 FROM tags WHERE task_id = t.id AND tag = 'urgent')
  AND EXISTS (SELECT 1 FROM tags WHERE task_id = t.id AND tag = 'boss') ORDER BY title;
-- owners with open urgent work
SELECT DISTINCT owner FROM projects JOIN tasks USING (pid) JOIN tags ON task_id = id WHERE tag = 'urgent' AND done = 0;
-- untagged tasks
SELECT title FROM tasks LEFT JOIN tags ON task_id = id WHERE tag IS NULL ORDER BY title;
-- close everything tagged chore
UPDATE tasks SET done = 1 WHERE id IN (SELECT task_id FROM tags WHERE tag = 'chore');
SELECT pname FROM projects p WHERE (SELECT count(*) FROM tasks WHERE tasks.pid = p.pid AND done = 0) = 0 ORDER BY pname;
DELETE FROM projects WHERE pid NOT IN (SELECT pid FROM tasks);
SELECT pid, pname FROM projects ORDER BY pid;
INSERT INTO tasks (pid, title) VALUES ((SELECT pid FROM projects WHERE pname = 'trip'), NULL);
SELECT title FROM tasks JOIN tags ON tags.task_id = tasks.id WHERE id = 6 ORDER BY tag;
SELECT t.title FROM tasks t JOIN tags g ON g.task_id = t.id WHERE g.tag = 'boss' ORDER BY t.id;
SELECT tag FROM tags JOIN tasks ON task_id = id JOIN projects USING (pid) WHERE pname = 'work' ORDER BY title, tag;
