-- a view is computed when used, against the current rows
CREATE TABLE queue (id INTEGER PRIMARY KEY, job TEXT, done INTEGER DEFAULT 0);
CREATE VIEW pending AS SELECT id, job FROM queue WHERE done = 0;
CREATE VIEW stats AS SELECT count(*) AS total, sum(done) AS finished FROM queue;
SELECT total, finished FROM stats;
INSERT INTO queue (job) VALUES ('wash'), ('dry'), ('fold');
SELECT id, job FROM pending ORDER BY id;
UPDATE queue SET done = 1 WHERE job = 'wash';
SELECT job FROM pending ORDER BY job;
SELECT total, finished FROM stats;
BEGIN;
UPDATE queue SET done = 1;
SELECT count(*) FROM pending;
ROLLBACK;
SELECT count(*) FROM pending;
