-- the window-only names need OVER; aggregates without OVER stay aggregates
CREATE TABLE t (a INTEGER);
INSERT INTO t VALUES (3), (1), (2);
SELECT row_number() FROM t;
SELECT a, rank() FROM t;
SELECT dense_rank() FROM t;
SELECT percent_rank() FROM t;
SELECT cume_dist() FROM t;
SELECT ntile(2) FROM t;
SELECT lag(a) FROM t;
SELECT lead(a, 1) FROM t;
SELECT first_value(a) FROM t;
SELECT last_value(a) FROM t;
SELECT nth_value(a, 1) FROM t;
SELECT sum(a), max(a), count(*) FROM t;
