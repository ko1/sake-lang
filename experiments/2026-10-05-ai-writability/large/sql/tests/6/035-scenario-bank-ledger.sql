-- scenario: a ledger with running balances, overdraft detection and a transaction
CREATE TABLE account (id INTEGER PRIMARY KEY, owner TEXT NOT NULL);
CREATE TABLE entry (id INTEGER PRIMARY KEY, account_id INTEGER NOT NULL, day INTEGER NOT NULL, amount INTEGER NOT NULL, memo TEXT);
INSERT INTO account (owner) VALUES ('ivy'), ('joe');
INSERT INTO entry (account_id, day, amount, memo) VALUES
  (1, 1, 500, 'salary'), (1, 2, -120, 'rent'), (1, 2, -40, 'food'), (1, 5, -400, 'car'),
  (2, 1, 100, 'gift'), (2, 3, -150, 'phone'), (2, 4, 300, 'refund');
INSERT INTO entry (account_id, day, amount) VALUES (1, 6, 'lots');
SELECT id, account_id, day, amount, sum(amount) OVER (PARTITION BY account_id ORDER BY day, id) AS bal
  FROM entry ORDER BY account_id, day, id;
-- balance at the end of each day (peers share the end-of-day value)
SELECT account_id, day, sum(amount) OVER (PARTITION BY account_id ORDER BY day) FROM entry ORDER BY account_id, day, id;
-- entries that left the account below zero
SELECT id, memo, bal FROM (SELECT id, memo, sum(amount) OVER (PARTITION BY account_id ORDER BY day, id) AS bal FROM entry)
  WHERE bal < 0 ORDER BY id;
-- the largest debit so far
SELECT id, min(amount) OVER (PARTITION BY account_id ORDER BY day, id ROWS UNBOUNDED PRECEDING) FROM entry ORDER BY id;
-- days between entries
SELECT id, day - lag(day, 1, day) OVER (PARTITION BY account_id ORDER BY day, id) AS wait FROM entry ORDER BY id;
BEGIN;
INSERT INTO entry (account_id, day, amount, memo) VALUES (1, 6, 200, 'bonus');
UPDATE entry SET amount = amount - 10 WHERE memo = 'rent';
SELECT a.owner, e.day, sum(e.amount) OVER (PARTITION BY a.id ORDER BY e.day, e.id) FROM entry AS e JOIN account AS a ON a.id = e.account_id
  WHERE a.owner = 'ivy' ORDER BY e.id;
COMMIT;
SELECT owner, (SELECT sum(amount) FROM entry WHERE account_id = account.id) FROM account ORDER BY owner;
SELECT account_id, count(*), sum(amount), rank() OVER (ORDER BY sum(amount) DESC) FROM entry GROUP BY account_id ORDER BY account_id;
SELECT id, memo, last_value(memo) OVER (PARTITION BY account_id ORDER BY day, id ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS nxt
  FROM entry ORDER BY id;
SELECT id, group_concat(amount, ';') OVER (PARTITION BY account_id ORDER BY id ROWS 2 PRECEDING) FROM entry ORDER BY id;
DELETE FROM entry WHERE amount < -300;
SELECT account_id, id, ntile(2) OVER (PARTITION BY account_id ORDER BY id) FROM entry ORDER BY account_id, id;
