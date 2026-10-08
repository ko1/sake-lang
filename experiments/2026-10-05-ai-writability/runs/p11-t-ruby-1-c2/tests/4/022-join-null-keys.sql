-- NULL = NULL is not true, so NULL keys never match in ON; IS does match them.
CREATE TABLE a (k INTEGER, v TEXT);
CREATE TABLE b (k INTEGER, w TEXT);
INSERT INTO a VALUES (1, 'a1'), (NULL, 'a2'), (2, 'a3');
INSERT INTO b VALUES (NULL, 'b1'), (2, 'b2'), (NULL, 'b3');
SELECT v, w FROM a JOIN b ON a.k = b.k ORDER BY v;
SELECT v, w FROM a JOIN b USING (k) ORDER BY v;
SELECT v, w FROM a LEFT JOIN b ON a.k = b.k ORDER BY v;
SELECT v, w FROM a JOIN b ON a.k IS b.k ORDER BY v, w;
