-- the default frame ends at the current row's last peer
CREATE TABLE q (id INTEGER, g TEXT, v INTEGER);
INSERT INTO q VALUES (1,'a',10),(2,'a',30),(3,'a',20),(4,'b',5),(5,'b',7);
SELECT id, first_value(v) OVER (PARTITION BY g ORDER BY id), last_value(v) OVER (PARTITION BY g ORDER BY id) FROM q ORDER BY id;
SELECT id, last_value(v) OVER (PARTITION BY g ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM q ORDER BY id;
SELECT id, first_value(id) OVER (ORDER BY v DESC), last_value(id) OVER (ORDER BY v DESC ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) FROM q ORDER BY id;
-- without ORDER BY the frame is the whole partition; one-row partitions have a known answer
SELECT g, v, first_value(v) OVER (PARTITION BY v) FROM q ORDER BY id;
