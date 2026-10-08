CREATE TABLE readings (sensor TEXT, val INTEGER);
INSERT INTO readings VALUES ('s1', 5), ('s2', NULL), ('s1', NULL), ('s3', 0), ('s2', NULL);
SELECT sensor, sum(val), total(val), avg(val), count(val) FROM readings GROUP BY sensor ORDER BY sensor;
SELECT sensor FROM readings GROUP BY sensor HAVING sum(val) IS NULL ORDER BY sensor;
SELECT sensor, coalesce(sum(val), -1) FROM readings GROUP BY sensor ORDER BY 2, 1;
