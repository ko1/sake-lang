-- lag(x, k, d) / lead(x, k, d)
CREATE TABLE s (n INTEGER, w TEXT);
INSERT INTO s VALUES (1,'one'),(2,'two'),(3,'three'),(4,'four'),(5,'five');
SELECT n, lag(w, 2) OVER (ORDER BY n), lead(w, 2) OVER (ORDER BY n) FROM s ORDER BY n;
SELECT n, lag(n, 1, 0) OVER (ORDER BY n), lead(n, 3, -1) OVER (ORDER BY n) FROM s ORDER BY n;
SELECT n, lag(w, 1, 'start') OVER (ORDER BY n DESC), lead(w, 1, 'end') OVER (ORDER BY n DESC) FROM s ORDER BY n;
-- k = 0 is the row itself; a k past the partition gives the default
SELECT n, lag(w, 0) OVER (ORDER BY n), lead(n, 9, 99) OVER (ORDER BY n) FROM s ORDER BY n;
SELECT n, lag(n * 10, 1, NULL) OVER (ORDER BY n) FROM s ORDER BY n;
