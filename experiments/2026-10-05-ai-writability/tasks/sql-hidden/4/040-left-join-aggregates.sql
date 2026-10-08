-- total, avg, group_concat and count over LEFT JOIN groups, some of them all NULL.
CREATE TABLE trips (tid INTEGER, dest TEXT);
CREATE TABLE costs (tid INTEGER, what TEXT, eur REAL);
INSERT INTO trips VALUES (1, 'Rome'), (2, 'Oslo'), (3, 'Lima');
INSERT INTO costs VALUES (1, 'hotel', 300.0), (1, 'food', 120.5), (2, 'train', 59.9), (1, 'museum', NULL);
SELECT dest, total(eur), sum(eur), avg(eur), count(what) FROM trips LEFT JOIN costs USING (tid) GROUP BY tid ORDER BY tid;
SELECT dest, group_concat(what, ' ' ORDER BY what DESC) FROM trips LEFT JOIN costs USING (tid) GROUP BY dest ORDER BY dest;
SELECT count(DISTINCT dest), count(*) FROM trips LEFT JOIN costs USING (tid) WHERE eur IS NULL;
SELECT dest FROM trips LEFT JOIN costs USING (tid) GROUP BY dest HAVING total(eur) < 100 ORDER BY dest;
