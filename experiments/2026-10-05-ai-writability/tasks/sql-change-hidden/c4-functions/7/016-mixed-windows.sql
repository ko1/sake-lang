-- mixed: the new functions with window functions and a view
CREATE TABLE runs (runner TEXT, lap INTEGER, secs INTEGER);
INSERT INTO runs VALUES ('kim', 1, 60), ('kim', 2, 58), ('kim', 3, 61), ('lee', 1, 55), ('lee', 2, 57);
SELECT runner, lap, sign(secs - lag(secs) OVER (PARTITION BY runner ORDER BY lap)) AS trend
  FROM runs ORDER BY runner, lap;
SELECT concat_ws('#', runner, rank() OVER (ORDER BY secs)) AS r FROM runs ORDER BY r;
CREATE VIEW initials AS SELECT DISTINCT char(unicode(upper(runner))) AS i FROM runs;
SELECT i FROM initials ORDER BY i;
SELECT runner, group_concat(lap, '') OVER (PARTITION BY runner ORDER BY lap) FROM runs
  WHERE sign(secs - 58) > 0 ORDER BY runner, lap;
