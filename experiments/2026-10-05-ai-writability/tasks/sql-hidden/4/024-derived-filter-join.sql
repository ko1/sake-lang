-- Subquery sources with WHERE, ORDER BY and LIMIT inside, joined to a table.
CREATE TABLE runs (runner TEXT, km REAL, day INTEGER);
CREATE TABLE runners (runner TEXT, club TEXT);
INSERT INTO runs VALUES ('ana', 5.0, 1), ('ben', 10.0, 1), ('ana', 21.1, 2), ('cy', 3.5, 2), ('ben', 7.25, 3);
INSERT INTO runners VALUES ('ana', 'north'), ('ben', 'south'), ('cy', 'north'), ('dan', 'east');
SELECT r.runner, club, km FROM (SELECT runner, km FROM runs ORDER BY km DESC LIMIT 2) r JOIN runners USING (runner)
  ORDER BY km;
SELECT club, coalesce(t.total, 0.0) FROM runners LEFT JOIN (SELECT runner, sum(km) AS total FROM runs WHERE day > 1
  GROUP BY runner) AS t USING (runner) ORDER BY club, runner;
SELECT club, max(km) FROM runners JOIN (SELECT * FROM runs WHERE km < 20) USING (runner) GROUP BY club ORDER BY club;
