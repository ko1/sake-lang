CREATE TABLE acct (id INTEGER, bal INTEGER, flag TEXT);
INSERT INTO acct VALUES (1, -20, NULL), (2, 0, NULL), (3, 150, NULL), (4, NULL, NULL);
UPDATE acct SET flag = CASE WHEN bal < 0 THEN 'overdrawn' WHEN bal = 0 THEN 'empty' WHEN bal > 100 THEN 'rich' END;
SELECT id, coalesce(flag, 'unknown') FROM acct ORDER BY id;
UPDATE acct SET bal = CASE flag WHEN 'overdrawn' THEN 0 WHEN 'rich' THEN bal - 100 ELSE bal END;
SELECT id, bal FROM acct ORDER BY id;
