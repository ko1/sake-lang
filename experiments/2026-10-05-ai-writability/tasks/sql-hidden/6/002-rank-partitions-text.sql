CREATE TABLE entry (cls TEXT, kid TEXT, grade TEXT);
INSERT INTO entry VALUES ('x','al','B'),('x','bo','A'),('x','cy','B'),('x','di','C'),('y','ed','A'),('y','fe','A'),('y','gu','A'),('y','hi','B');
SELECT cls, kid, rank() OVER (PARTITION BY cls ORDER BY grade), dense_rank() OVER (PARTITION BY cls ORDER BY grade) FROM entry ORDER BY cls, kid;
SELECT kid, rank() OVER (ORDER BY grade DESC), dense_rank() OVER (ORDER BY grade DESC) FROM entry ORDER BY kid;
SELECT kid, rank() OVER (ORDER BY cls, grade), dense_rank() OVER (PARTITION BY grade) FROM entry ORDER BY kid;
