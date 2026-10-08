-- INSERT, UPDATE and DELETE on a view are errors, and change nothing
CREATE TABLE acct (id INTEGER PRIMARY KEY, bal INTEGER);
INSERT INTO acct (bal) VALUES (10), (20);
CREATE VIEW rich AS SELECT id, bal FROM acct WHERE bal > 15;
INSERT INTO rich SELECT 3, 99;
WITH x AS (SELECT 1 AS id) INSERT INTO rich (id) SELECT id FROM x;
UPDATE rich SET bal = 0 WHERE id = 2;
DELETE FROM rich WHERE bal > 0;
SELECT id, bal FROM rich;
BEGIN;
DELETE FROM rich;
UPDATE acct SET bal = bal + 10;
COMMIT;
SELECT id, bal FROM rich ORDER BY id;
