-- without ORDER BY the frame is the whole partition
CREATE TABLE item (id INTEGER, cat TEXT, price REAL, qty INTEGER);
INSERT INTO item VALUES (1,'tool',9.5,3),(2,'tool',20.0,NULL),(3,'food',2.25,10),(4,'food',4.75,2),(5,'toy',15.0,1);
SELECT id, cat, count(*) OVER (PARTITION BY cat), count(qty) OVER (PARTITION BY cat), sum(qty) OVER (PARTITION BY cat) FROM item ORDER BY id;
SELECT id, avg(price) OVER (PARTITION BY cat), total(qty) OVER (PARTITION BY cat), max(price) OVER () FROM item ORDER BY id;
SELECT id, price - avg(price) OVER (PARTITION BY cat) AS diff FROM item ORDER BY id;
SELECT id, qty * 100 / sum(qty) OVER () AS pct FROM item WHERE qty IS NOT NULL ORDER BY id;
