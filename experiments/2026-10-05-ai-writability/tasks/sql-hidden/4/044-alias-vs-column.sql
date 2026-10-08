-- A source column wins over a result alias of the same name; aliases still work otherwise.
CREATE TABLE emp (id INTEGER, pay INTEGER);
CREATE TABLE adj (id INTEGER, pct INTEGER);
INSERT INTO emp VALUES (1, 100), (2, 200), (3, 300);
INSERT INTO adj VALUES (1, 10), (2, 50), (3, 0);
SELECT e.id, pay * (100 + pct) / 100 AS pay FROM emp e JOIN adj a ON a.id = e.id WHERE pay > 150 ORDER BY e.id;
SELECT e.id, pay * (100 + pct) / 100 AS newpay FROM emp e JOIN adj USING (id) WHERE newpay > 150 ORDER BY newpay DESC, e.id;
SELECT pct AS id, emp.id FROM emp JOIN adj USING (id) ORDER BY id;
SELECT e.id AS who, pct FROM emp e, adj a WHERE e.id = a.id AND who >= 2 ORDER BY who;
