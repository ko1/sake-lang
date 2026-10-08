-- A correlated subquery is evaluated again for each row of the enclosing query.
CREATE TABLE teams (id INTEGER, name TEXT);
CREATE TABLE players (team_id INTEGER, player TEXT, goals INTEGER);
INSERT INTO teams VALUES (1, 'Reds'), (2, 'Blues'), (3, 'Greens');
INSERT INTO players VALUES (1, 'ann', 5), (1, 'bob', 2), (2, 'cid', 7), (2, 'dee', 1), (2, 'eve', 0);
SELECT name, (SELECT count(*) FROM players WHERE team_id = teams.id) FROM teams ORDER BY id;
SELECT name, (SELECT sum(goals) FROM players WHERE team_id = id) FROM teams ORDER BY id;
SELECT name, (SELECT player FROM players WHERE team_id = teams.id ORDER BY goals DESC LIMIT 1) AS top
  FROM teams ORDER BY name;
SELECT player FROM players p WHERE goals = (SELECT max(goals) FROM players WHERE team_id = p.team_id)
  ORDER BY player;
SELECT name FROM teams ORDER BY (SELECT count(*) FROM players WHERE team_id = teams.id), name;
