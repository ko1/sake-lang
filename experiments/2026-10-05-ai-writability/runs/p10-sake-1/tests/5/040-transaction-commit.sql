-- BEGIN ... COMMIT keeps the changes
CREATE TABLE acct (name TEXT, bal INTEGER);
INSERT INTO acct VALUES ('a', 100), ('b', 50);
BEGIN;
UPDATE acct SET bal = bal - 30 WHERE name = 'a';
UPDATE acct SET bal = bal + 30 WHERE name = 'b';
SELECT name, bal FROM acct ORDER BY name;
COMMIT;
SELECT name, bal FROM acct ORDER BY name;
BEGIN TRANSACTION;
INSERT INTO acct VALUES ('c', 5);
COMMIT TRANSACTION;
SELECT count(*) FROM acct;
