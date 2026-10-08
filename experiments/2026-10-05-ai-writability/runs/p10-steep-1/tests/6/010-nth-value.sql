-- nth_value(x, n): x on the frame's n-th row, NULL when the frame is shorter
CREATE TABLE m (k INTEGER, name TEXT);
INSERT INTO m VALUES (1,'ada'),(2,'bea'),(3,'cyd'),(4,'dov'),(5,'eli');
SELECT k, nth_value(name, 2) OVER (ORDER BY k) FROM m ORDER BY k;
SELECT k, nth_value(name, 3) OVER (ORDER BY k ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM m ORDER BY k;
SELECT k, nth_value(k, 2) OVER (ORDER BY k ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM m ORDER BY k;
SELECT k, nth_value(name, 1) OVER (ORDER BY k DESC ROWS 2 PRECEDING) FROM m ORDER BY k;
