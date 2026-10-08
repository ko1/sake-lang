-- A small sign-up desk: case-insensitive logins, reports grouped and sorted by collation.
CREATE TABLE members (id INTEGER PRIMARY KEY, login TEXT NOT NULL UNIQUE COLLATE NOCASE, team TEXT COLLATE NOCASE, joined INTEGER);
INSERT INTO members (login, team, joined) VALUES ('Ada', 'Red', 2020), ('bram', 'blue', 2021), ('Cleo', 'RED', 2022);
INSERT INTO members (login, team, joined) VALUES ('ADA', 'blue', 2023);
BEGIN;
INSERT INTO members (login, team, joined) VALUES ('dion', 'Blue', 2023);
INSERT INTO members (login, team, joined) VALUES ('Bram', 'red', 2024);
COMMIT;
SELECT lower(team), count(*), min(joined) FROM members GROUP BY team ORDER BY 1;
SELECT login FROM members WHERE team = 'BLUE' ORDER BY login DESC;
SELECT id, login FROM members WHERE login IN (SELECT 'CLEO' UNION ALL SELECT 'dion') ORDER BY id;
CREATE VIEW reds AS SELECT login, joined FROM members WHERE team = 'red';
SELECT login FROM reds WHERE login > 'b' ORDER BY joined;
SELECT login, rank() OVER (PARTITION BY team ORDER BY joined) FROM members ORDER BY login;
