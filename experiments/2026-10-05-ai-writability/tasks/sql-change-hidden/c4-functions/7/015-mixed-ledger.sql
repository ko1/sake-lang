-- mixed: sign in GROUP BY, concat_ws with group_concat, concat in ORDER BY
CREATE TABLE ledger (id INTEGER PRIMARY KEY, who TEXT NOT NULL, amount INTEGER);
INSERT INTO ledger (who, amount) VALUES ('ann', 40), ('bob', -15), ('ann', -5), ('cy', 0), ('bob', 25), ('cy', NULL);
SELECT sign(amount) AS dir, count(*), sum(amount) FROM ledger GROUP BY dir ORDER BY dir;
SELECT who, concat_ws('/', count(*), sum(amount)) FROM ledger GROUP BY who ORDER BY who;
SELECT who, sign(sum(amount)) FROM ledger GROUP BY who HAVING sign(sum(amount)) >= 0 ORDER BY who;
SELECT group_concat(concat(who, ':', amount), ';' ORDER BY id) FROM ledger;
SELECT concat(who, id) AS tag FROM ledger WHERE amount < 0 ORDER BY concat(who, id) DESC;
