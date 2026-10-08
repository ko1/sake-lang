-- One table joined to itself under two aliases.
CREATE TABLE emp (id INTEGER PRIMARY KEY, name TEXT, boss INTEGER);
INSERT INTO emp VALUES (1, 'Ada', NULL), (2, 'Ben', 1), (3, 'Cy', 1), (4, 'Di', 2), (5, 'Ed', 4);
SELECT e.name, m.name FROM emp e JOIN emp m ON e.boss = m.id ORDER BY e.name;
SELECT e.name, m.name FROM emp e LEFT JOIN emp m ON e.boss = m.id ORDER BY e.id;
SELECT m.name, count(e.id) FROM emp m LEFT JOIN emp e ON e.boss = m.id GROUP BY m.id ORDER BY m.id;
SELECT e.name, g.name FROM emp e JOIN emp m ON e.boss = m.id JOIN emp g ON m.boss = g.id ORDER BY e.name;
