-- windows see all rows; DISTINCT, ORDER BY, LIMIT and OFFSET come after
CREATE TABLE c (id INTEGER, color TEXT);
INSERT INTO c VALUES (1,'red'),(2,'blue'),(3,'red'),(4,'green'),(5,'blue'),(6,'red');
SELECT DISTINCT color, count(*) OVER (PARTITION BY color) FROM c ORDER BY color;
SELECT id, row_number() OVER (ORDER BY id) FROM c ORDER BY id LIMIT 2 OFFSET 3;
SELECT id, count(*) OVER () FROM c WHERE color = 'red' ORDER BY id;
SELECT DISTINCT color, min(id) OVER (PARTITION BY color) AS first_id FROM c ORDER BY first_id DESC LIMIT 2;
SELECT id, sum(id) OVER (ORDER BY id) AS run FROM c ORDER BY run DESC LIMIT 1;
