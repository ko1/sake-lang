-- Accounts and transfers between them.
CREATE TABLE accounts (no INTEGER PRIMARY KEY, owner TEXT NOT NULL, opened INTEGER);
CREATE TABLE transfers (id INTEGER PRIMARY KEY, src INTEGER, dst INTEGER, amount INTEGER NOT NULL);
INSERT INTO accounts VALUES (1, 'ann', 2020), (2, 'bob', 2021), (3, 'ann', 2022), (4, 'cyd', 2023);
INSERT INTO transfers (src, dst, amount) VALUES (NULL, 1, 500), (NULL, 2, 300), (1, 2, 120), (2, 3, 50),
  (1, 3, 75), (3, 1, 10), (NULL, 4, 0);
INSERT INTO transfers (src, dst, amount) VALUES (4, 1, NULL);
-- balance: money in minus money out
SELECT no, owner, coalesce((SELECT sum(amount) FROM transfers WHERE dst = no), 0)
  - coalesce((SELECT sum(amount) FROM transfers WHERE src = no), 0) AS balance FROM accounts ORDER BY no;
-- transfers with both owners' names; deposits have no source
SELECT t.id, s.owner, d.owner, amount FROM transfers t LEFT JOIN accounts s ON s.no = t.src
  JOIN accounts d ON d.no = t.dst ORDER BY t.id;
-- transfers between accounts of the same owner
SELECT t.id FROM transfers t JOIN accounts s ON s.no = t.src JOIN accounts d ON d.no = t.dst
  WHERE s.owner = d.owner ORDER BY t.id;
-- owners with total balance
SELECT owner, sum(bal) FROM (SELECT owner, (SELECT total(amount) FROM transfers WHERE dst = no)
  - (SELECT total(amount) FROM transfers WHERE src = no) AS bal FROM accounts) GROUP BY owner ORDER BY owner;
-- accounts that never sent money
SELECT no FROM accounts WHERE no NOT IN (SELECT src FROM transfers WHERE src IS NOT NULL) ORDER BY no;
SELECT no FROM accounts WHERE no NOT IN (SELECT src FROM transfers) ORDER BY no;
-- largest single outgoing transfer per account that sent any
SELECT src, max(amount) FROM transfers JOIN accounts ON no = src GROUP BY src ORDER BY src;
-- close cyd's account: delete its transfers first
DELETE FROM transfers WHERE dst IN (SELECT no FROM accounts WHERE owner = 'cyd');
DELETE FROM accounts WHERE owner = 'cyd';
SELECT count(*), sum(amount) FROM transfers;
SELECT a.no, b.no FROM accounts a JOIN accounts b ON a.owner = b.owner AND a.no < b.no ORDER BY a.no;
SELECT owner FROM accounts a JOIN transfers ON a.no = src WHERE accounts.opened > 2020;
SELECT id, (SELECT owner, no FROM accounts WHERE no = src) FROM transfers;
SELECT owner, count(*) FROM accounts JOIN transfers ON dst = no GROUP BY owner ORDER BY owner;
SELECT EXISTS (SELECT 1 FROM transfers WHERE src = dst), NOT EXISTS (SELECT 1 FROM accounts WHERE owner = 'cyd');
