CREATE TABLE acct (id INTEGER PRIMARY KEY, bal INTEGER);
INSERT INTO acct (bal) VALUES (10), (20), (30);
UPDATE acct SET bal = 0 WHERE bal < avg(bal);
DELETE FROM acct WHERE bal = max(bal);
DELETE FROM acct WHERE bal = max(bal, 25);
SELECT count(*), sum(bal) FROM acct;
