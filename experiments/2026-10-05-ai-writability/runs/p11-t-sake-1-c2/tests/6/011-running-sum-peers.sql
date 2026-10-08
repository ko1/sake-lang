-- with ORDER BY and no frame, an aggregate runs up to the current row's last peer
CREATE TABLE sale (day INTEGER, amount INTEGER);
INSERT INTO sale VALUES (1, 10), (2, 5), (2, 7), (3, 1), (5, 20), (5, 2), (6, 4);
SELECT day, amount, sum(amount) OVER (ORDER BY day) FROM sale ORDER BY day, amount;
SELECT day, amount, count(*) OVER (ORDER BY day DESC) FROM sale ORDER BY day, amount;
-- ROWS UNBOUNDED PRECEDING stops at the current row instead (ties broken by amount here)
SELECT day, amount, sum(amount) OVER (ORDER BY day, amount ROWS UNBOUNDED PRECEDING) FROM sale ORDER BY day, amount;
SELECT day, amount, max(amount) OVER (ORDER BY day), min(amount) OVER (ORDER BY day) FROM sale ORDER BY day, amount;
