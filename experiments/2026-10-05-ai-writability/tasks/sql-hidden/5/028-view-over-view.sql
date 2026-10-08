-- a view may use another view
CREATE TABLE temp_log (day INTEGER, c REAL);
INSERT INTO temp_log VALUES (1, 10.0), (2, 25.0), (3, 30.5), (4, -2.0);
CREATE VIEW fahrenheit AS SELECT day, c * 9 / 5 + 32 AS f FROM temp_log;
CREATE VIEW hot AS SELECT day, f FROM fahrenheit WHERE f > 75;
SELECT day, f FROM hot ORDER BY day;
SELECT count(*) FROM hot;
UPDATE temp_log SET c = 26.0 WHERE day = 1;
SELECT day FROM hot ORDER BY day;
CREATE VIEW summary (hot_days, max_f) AS SELECT count(*), max(f) FROM hot;
SELECT hot_days, max_f FROM summary;
DROP VIEW summary;
DROP VIEW summary;
SELECT f FROM fahrenheit WHERE day = 4;
