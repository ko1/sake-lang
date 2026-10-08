-- UNION keeps one of each distinct row, from both sides together
CREATE TABLE a (x INTEGER, y TEXT);
CREATE TABLE b (x INTEGER, y TEXT);
INSERT INTO a VALUES (1, 'p'), (1, 'p'), (2, 'q');
INSERT INTO b VALUES (2, 'q'), (3, 'r'), (2, 'Q');
SELECT x, y FROM a UNION SELECT x, y FROM b ORDER BY x, y;
SELECT x FROM a UNION SELECT x FROM b ORDER BY x;
SELECT count(*) FROM (SELECT y FROM a UNION SELECT y FROM b);
