-- text that is a whole number is stored in the INTEGER PRIMARY KEY as that number
CREATE TABLE kv (k INTEGER PRIMARY KEY, v TEXT);
INSERT INTO kv VALUES ('  12', 'a');
INSERT INTO kv VALUES ('5.0', 'b');
INSERT INTO kv VALUES (1e1, 'c');
INSERT INTO kv VALUES ('12', 'd');
INSERT INTO kv VALUES (5, 'e');
INSERT INTO kv (v) VALUES ('f');
SELECT k, typeof(k), v FROM kv ORDER BY k;
SELECT v FROM kv WHERE k = '10' OR k IN ('5') ORDER BY v;
