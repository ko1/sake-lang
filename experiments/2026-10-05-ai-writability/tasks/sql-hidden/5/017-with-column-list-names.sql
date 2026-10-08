-- a cte's column list replaces the select's own names
CREATE TABLE emp (name TEXT, pay INTEGER);
INSERT INTO emp VALUES ('a', 10), ('b', 20);
WITH e(who, money) AS (SELECT name, pay FROM emp) SELECT who FROM e WHERE money > 15;
WITH e(who, money) AS (SELECT name, pay FROM emp) SELECT name FROM e;
WITH e(who, money) AS (SELECT name, pay FROM emp) SELECT e.money FROM e ORDER BY e.money DESC;
WITH e AS (SELECT name, pay * 2 AS twice FROM emp) SELECT name, twice FROM e ORDER BY name;
WITH e(k) AS (SELECT 5 UNION SELECT 6) SELECT k FROM e ORDER BY k;
