-- a job queue: rowid as arrival order, take the oldest, requeue it at the end
CREATE TABLE job (cmd TEXT, tries INTEGER DEFAULT 0);
CREATE TABLE head (r INTEGER, lastr INTEGER);
INSERT INTO job (cmd) VALUES ('build'), ('test'), ('lint');
INSERT INTO head SELECT min(rowid), max(rowid) FROM job;
SELECT rowid, cmd FROM job WHERE rowid = (SELECT r FROM head);
UPDATE job SET tries = tries + 1, rowid = (SELECT lastr + 1 FROM head) WHERE rowid = (SELECT r FROM head);
DELETE FROM head;
INSERT INTO head SELECT min(rowid), max(rowid) FROM job;
DELETE FROM job WHERE rowid = (SELECT r FROM head);
INSERT INTO job (cmd) VALUES ('deploy');
SELECT rowid, cmd, tries FROM job ORDER BY rowid;
SELECT cmd, row_number() OVER (ORDER BY rowid) AS pos FROM job ORDER BY pos;
