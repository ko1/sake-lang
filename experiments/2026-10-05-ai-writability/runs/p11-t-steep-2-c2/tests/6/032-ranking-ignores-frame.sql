-- ranking functions, lag and lead ignore the frame clause
CREATE TABLE r (id INTEGER, v INTEGER);
INSERT INTO r VALUES (1,5),(2,3),(3,5),(4,8),(5,1);
SELECT id, row_number() OVER (ORDER BY id ROWS CURRENT ROW), rank() OVER (ORDER BY v ROWS BETWEEN 1 FOLLOWING AND 2 FOLLOWING) FROM r ORDER BY id;
SELECT id, dense_rank() OVER (ORDER BY v RANGE CURRENT ROW), ntile(2) OVER (ORDER BY id ROWS CURRENT ROW) FROM r ORDER BY id;
SELECT id, lag(v) OVER (ORDER BY id ROWS CURRENT ROW), lead(v, 2) OVER (ORDER BY id ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) FROM r ORDER BY id;
SELECT id, percent_rank() OVER (ORDER BY v ROWS CURRENT ROW), cume_dist() OVER (ORDER BY v ROWS 1 PRECEDING) FROM r ORDER BY id;
-- first_value does use it
SELECT id, first_value(v) OVER (ORDER BY id ROWS CURRENT ROW) FROM r ORDER BY id;
