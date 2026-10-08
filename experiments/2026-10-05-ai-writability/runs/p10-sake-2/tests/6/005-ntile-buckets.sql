-- ntile(n): larger buckets first
CREATE TABLE r (id INTEGER, grp TEXT);
INSERT INTO r VALUES (1,'x'),(2,'x'),(3,'x'),(4,'x'),(5,'x'),(6,'x'),(7,'x'),(8,'y'),(9,'y'),(10,'y');
SELECT id, ntile(3) OVER (ORDER BY id), ntile(2) OVER (ORDER BY id DESC), ntile(1) OVER (ORDER BY id) FROM r ORDER BY id;
SELECT id, ntile(4) OVER (PARTITION BY grp ORDER BY id) FROM r ORDER BY id;
-- more buckets than rows: one row each
SELECT id, ntile(20) OVER (ORDER BY id) FROM r WHERE grp = 'y' ORDER BY id;
