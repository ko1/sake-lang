-- EXISTS is 1 when the subquery has a row, whatever the row holds.
CREATE TABLE jobs (id INTEGER, state TEXT);
INSERT INTO jobs VALUES (1, 'done'), (2, 'failed');
SELECT EXISTS (SELECT 1 FROM jobs WHERE state = 'failed');
SELECT EXISTS (SELECT 1 FROM jobs WHERE state = 'queued');
SELECT NOT EXISTS (SELECT * FROM jobs WHERE state = 'queued');
SELECT EXISTS (SELECT NULL);
SELECT EXISTS (SELECT id, state FROM jobs);
SELECT EXISTS (SELECT count(*) FROM jobs WHERE 0);
SELECT id FROM jobs WHERE EXISTS (SELECT 1 FROM jobs WHERE state = 'failed') ORDER BY id;
DELETE FROM jobs;
SELECT EXISTS (SELECT * FROM jobs), typeof(NOT EXISTS (SELECT * FROM jobs));
