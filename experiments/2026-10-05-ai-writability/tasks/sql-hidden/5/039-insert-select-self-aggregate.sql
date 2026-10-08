-- an INSERT reading its own table sees it as it was before the statement
CREATE TABLE ledger (id INTEGER PRIMARY KEY, amount INTEGER);
INSERT INTO ledger (amount) VALUES (5), (7);
INSERT INTO ledger (amount) SELECT sum(amount) FROM ledger;
SELECT id, amount FROM ledger ORDER BY id;
INSERT INTO ledger (amount) SELECT amount FROM ledger WHERE amount = 7 UNION ALL SELECT count(*) FROM ledger;
SELECT id, amount FROM ledger ORDER BY amount, id;
INSERT INTO ledger SELECT id + 100, -amount FROM ledger;
SELECT count(*), sum(amount) FROM ledger;
