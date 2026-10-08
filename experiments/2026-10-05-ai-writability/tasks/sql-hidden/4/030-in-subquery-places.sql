-- IN ( select ) in the result columns, in ON, and in DELETE.
CREATE TABLE langs (name TEXT, year INTEGER);
CREATE TABLE used (lang TEXT, team TEXT);
INSERT INTO langs VALUES ('c', 1972), ('ruby', 1995), ('go', 2009), ('lisp', 1958), ('rust', 2010);
INSERT INTO used VALUES ('ruby', 'web'), ('go', 'infra'), ('c', 'infra'), ('ruby', 'infra');
SELECT name, name IN (SELECT lang FROM used), name NOT IN (SELECT lang FROM used WHERE team = 'web') FROM langs ORDER BY year;
SELECT team, name FROM (SELECT DISTINCT team FROM used) t JOIN langs
  ON name IN (SELECT lang FROM used WHERE used.team = t.team) ORDER BY team, name;
SELECT name FROM langs WHERE year IN (SELECT max(year) FROM langs) ORDER BY name;
DELETE FROM langs WHERE name NOT IN (SELECT lang FROM used);
SELECT name FROM langs ORDER BY name;
