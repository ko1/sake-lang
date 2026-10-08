CREATE TABLE q (id INTEGER, k TEXT);
INSERT INTO q VALUES (1,'a'),(2,'a'),(3,'a'),(4,'a'),(5,'a'),(6,'b'),(7,'b'),(8,'b'),(9,'b'),(10,'b'),(11,'b'),(12,'c');
SELECT id, ntile(4) OVER (ORDER BY id) FROM q ORDER BY id;
SELECT id, ntile(5) OVER (ORDER BY id DESC) FROM q ORDER BY id;
SELECT id, k, ntile(3) OVER (PARTITION BY k ORDER BY id) FROM q ORDER BY id;
SELECT k, ntile(2) OVER (PARTITION BY k ORDER BY min(id)), count(*) FROM q GROUP BY k, id > 3 ORDER BY k, 2;
SELECT id, ntile(2 + 1) OVER (ORDER BY id) FROM q WHERE id <= 4 ORDER BY id;
