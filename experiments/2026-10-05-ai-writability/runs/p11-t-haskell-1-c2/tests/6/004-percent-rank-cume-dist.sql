-- percent_rank() and cume_dist() are REAL
CREATE TABLE t (k TEXT, v INTEGER);
INSERT INTO t VALUES ('a', 1), ('b', 2), ('c', 2), ('d', 3), ('e', 5);
SELECT k, percent_rank() OVER (ORDER BY v), cume_dist() OVER (ORDER BY v) FROM t ORDER BY k;
SELECT k, typeof(percent_rank() OVER (ORDER BY v)), typeof(cume_dist() OVER (ORDER BY v)) FROM t WHERE k = 'a';
-- a one-row partition
SELECT k, percent_rank() OVER (PARTITION BY v ORDER BY k), cume_dist() OVER (PARTITION BY v ORDER BY k) FROM t ORDER BY k;
-- no ORDER BY: all peers
SELECT k, percent_rank() OVER (), cume_dist() OVER () FROM t ORDER BY k;
