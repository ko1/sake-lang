CREATE TABLE meas (grp TEXT, v REAL);
INSERT INTO meas VALUES ('a', 0.1), ('a', 0.2), ('a', 0.3), ('b', 1e16), ('b', 2.0), ('b', -1e16), ('c', 2.5);
SELECT grp, sum(v), total(v), avg(v) FROM meas GROUP BY grp ORDER BY grp;
SELECT grp FROM meas GROUP BY grp HAVING sum(v) = 0.6 ORDER BY grp;
SELECT avg(v) * 3 FROM meas WHERE grp = 'b';
