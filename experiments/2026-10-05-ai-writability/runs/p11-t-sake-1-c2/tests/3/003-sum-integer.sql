CREATE TABLE ledger (amount INTEGER);
INSERT INTO ledger VALUES (100), (-30), (NULL), (45);
SELECT sum(amount), typeof(sum(amount)) FROM ledger;
SELECT sum(amount * 2) FROM ledger WHERE amount > 0;
SELECT sum(amount) FROM ledger WHERE amount IS NULL;
SELECT typeof(sum(amount)) FROM ledger WHERE amount IS NULL;
