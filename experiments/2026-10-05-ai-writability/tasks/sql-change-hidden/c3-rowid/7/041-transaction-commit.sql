-- committed rowid changes stay; a failed statement inside a transaction takes no numbers
CREATE TABLE ty (s TEXT NOT NULL);
BEGIN;
INSERT INTO ty VALUES ('a');
INSERT INTO ty (rowid, s) VALUES (60, 'b');
INSERT INTO ty VALUES ('c'), (NULL);
COMMIT;
INSERT INTO ty VALUES ('d');
SELECT rowid, s FROM ty ORDER BY rowid;
