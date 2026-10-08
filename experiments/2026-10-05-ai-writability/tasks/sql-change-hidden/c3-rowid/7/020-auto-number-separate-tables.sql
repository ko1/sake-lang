-- each table numbers its own rows; a failed statement takes no numbers
CREATE TABLE ta (v INTEGER NOT NULL);
CREATE TABLE tb (v INTEGER);
INSERT INTO ta VALUES (1), (2);
INSERT INTO tb VALUES (3);
INSERT INTO ta VALUES (4), (NULL);
INSERT INTO ta VALUES (5);
INSERT INTO tb VALUES (6), (7);
SELECT 'a', rowid, v FROM ta UNION ALL SELECT 'b', rowid, v FROM tb ORDER BY 1, 2;
