-- views over aggregates, filtered and joined like tables
CREATE TABLE vote (who TEXT, choice TEXT);
INSERT INTO vote VALUES ('a', 'tea'), ('b', 'coffee'), ('c', 'tea'), ('d', 'water'), ('e', 'tea'), ('f', 'coffee');
CREATE VIEW tally AS SELECT choice, count(*) AS n FROM vote GROUP BY choice;
SELECT choice, n FROM tally ORDER BY n DESC, choice;
SELECT choice FROM tally WHERE n = (SELECT max(n) FROM tally);
SELECT sum(n), count(*) FROM tally;
SELECT v.who FROM vote v JOIN tally t ON t.choice = v.choice WHERE t.n = 1;
CREATE VIEW share AS SELECT choice, n * 100 / (SELECT count(*) FROM vote) AS pct FROM tally;
SELECT choice, pct FROM share ORDER BY pct, choice;
INSERT INTO vote VALUES ('g', 'water'), ('h', 'water');
SELECT choice, pct FROM share ORDER BY pct DESC, choice;
