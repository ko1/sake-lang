-- Two aggregated subquery sources joined together.
CREATE TABLE income (person TEXT, amount INTEGER);
CREATE TABLE expense (person TEXT, amount INTEGER);
INSERT INTO income VALUES ('ann', 100), ('ann', 50), ('bob', 80), ('cid', 10);
INSERT INTO expense VALUES ('ann', 30), ('bob', 90), ('bob', 5), ('dee', 7);
SELECT i.person, i.total, e.total, i.total - e.total AS net
  FROM (SELECT person, sum(amount) AS total FROM income GROUP BY person) i
  JOIN (SELECT person, sum(amount) AS total FROM expense GROUP BY person) e ON e.person = i.person
  ORDER BY net DESC;
SELECT person, inc, coalesce(exp, 0)
  FROM (SELECT person, sum(amount) AS inc FROM income GROUP BY person)
  LEFT JOIN (SELECT person, sum(amount) AS exp FROM expense GROUP BY person) USING (person)
  ORDER BY person;
