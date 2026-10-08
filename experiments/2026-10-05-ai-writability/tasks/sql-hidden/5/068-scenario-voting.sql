-- scenario: an election with ranked ballots counted in rounds
CREATE TABLE ballot (voter INTEGER, rank INTEGER, cand TEXT, UNIQUE (voter, rank), UNIQUE (voter, cand));
INSERT INTO ballot VALUES (1, 1, 'ada'), (1, 2, 'bo'), (2, 1, 'bo'), (2, 2, 'ada'), (3, 1, 'cy'), (3, 2, 'bo');
INSERT INTO ballot VALUES (4, 1, 'ada'), (5, 1, 'cy'), (5, 2, 'ada'), (6, 1, 'bo'), (7, 1, 'ada'), (8, 1, 'bo'), (8, 2, 'cy');
INSERT INTO ballot VALUES (6, 2, 'bo');
CREATE TABLE out (cand TEXT UNIQUE);
CREATE VIEW live AS SELECT voter, min(rank) AS r FROM ballot WHERE cand NOT IN (SELECT cand FROM out) GROUP BY voter;
CREATE VIEW tally AS SELECT b.cand, count(*) AS votes FROM ballot b JOIN live l ON l.voter = b.voter AND l.r = b.rank GROUP BY b.cand;
SELECT cand, votes FROM tally ORDER BY votes DESC, cand;
INSERT INTO out SELECT cand FROM tally WHERE votes = (SELECT min(votes) FROM tally);
SELECT cand FROM out;
SELECT cand, votes FROM tally ORDER BY votes DESC, cand;
SELECT DISTINCT cand FROM ballot EXCEPT SELECT cand FROM out ORDER BY cand;
BEGIN;
INSERT INTO out SELECT cand FROM tally WHERE votes = (SELECT min(votes) FROM tally);
SELECT cand, votes FROM tally ORDER BY cand;
ROLLBACK;
SELECT count(*) FROM out;
WITH firsts AS (SELECT cand, count(*) AS n FROM ballot WHERE rank = 1 GROUP BY cand), seconds AS (SELECT cand, count(*) AS n FROM ballot WHERE rank = 2 GROUP BY cand)
SELECT 'first', cand, n FROM firsts UNION ALL SELECT 'second', cand, n FROM seconds ORDER BY 1, 2;
SELECT voter FROM ballot WHERE cand = 'ada' INTERSECT SELECT voter FROM ballot WHERE cand = 'bo' ORDER BY voter;
INSERT INTO out VALUES ('cy');
DELETE FROM tally WHERE cand = 'ada';
SELECT sum(votes) FROM tally;
