-- Subqueries as operands: precedence follows the operator, the subquery is one primary.
CREATE TABLE n (v INTEGER);
INSERT INTO n VALUES (2), (3);
SELECT (SELECT max(v) FROM n) * (SELECT min(v) FROM n) + 1, (SELECT max(v) FROM n) - (SELECT min(v) FROM n) * 2;
SELECT 'v' || (SELECT max(v) FROM n) + 1, (SELECT min(v) FROM n) || (SELECT max(v) FROM n) * 2;
SELECT EXISTS (SELECT 1 FROM n WHERE v > 2) + EXISTS (SELECT 1 FROM n WHERE v > 1) * 10;
SELECT 0 OR EXISTS (SELECT 1 FROM n), NOT EXISTS (SELECT 1 FROM n) AND 1, NOT (EXISTS (SELECT 1 FROM n));
SELECT (SELECT min(v) FROM n) < (SELECT max(v) FROM n) = 1, (SELECT min(v) FROM n) BETWEEN 1 AND (SELECT max(v) FROM n);
SELECT -(SELECT v FROM n ORDER BY v LIMIT 1) * -(SELECT v FROM n ORDER BY v DESC LIMIT 1);
