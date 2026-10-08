-- a column list on a view over a compound select
CREATE TABLE inbox (sender TEXT, subj TEXT);
CREATE TABLE outbox (rcpt TEXT, subj TEXT);
INSERT INTO inbox VALUES ('ann', 'hi'), ('bob', 'lunch');
INSERT INTO outbox VALUES ('ann', 're: hi'), ('cy', 'plans');
CREATE VIEW mail (dir, peer, topic) AS SELECT 'in', sender, subj FROM inbox UNION ALL SELECT 'out', rcpt, subj FROM outbox;
SELECT dir, peer, topic FROM mail ORDER BY peer, dir;
SELECT peer, count(*) FROM mail GROUP BY peer ORDER BY peer;
SELECT sender FROM mail;
CREATE VIEW peers AS SELECT sender FROM inbox UNION SELECT rcpt FROM outbox;
SELECT sender FROM peers ORDER BY sender;
SELECT rcpt FROM peers;
