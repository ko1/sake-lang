-- The unqualified USING column (left side's value) in WHERE, GROUP BY and ORDER BY.
CREATE TABLE stations (sid INTEGER, place TEXT);
CREATE TABLE readings (sid INTEGER, val INTEGER);
INSERT INTO stations VALUES (1, 'hill'), (2, 'lake'), (3, 'farm');
INSERT INTO readings VALUES (1, 7), (1, 9), (2, 4), (5, 1);
SELECT sid, count(val) FROM stations LEFT JOIN readings USING (sid) GROUP BY sid ORDER BY sid;
SELECT sid, place FROM stations LEFT JOIN readings USING (sid) WHERE sid >= 2 ORDER BY sid DESC;
SELECT sid, readings.sid, val FROM readings LEFT JOIN stations USING (sid) ORDER BY sid, val;
SELECT sid FROM readings LEFT JOIN stations USING (sid) WHERE place IS NULL;
SELECT sum(sid) FROM stations JOIN readings USING (sid);
