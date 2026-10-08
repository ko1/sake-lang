-- column count errors for INSERT ... SELECT, including compound and WITH forms
CREATE TABLE dst (a TEXT, b TEXT);
INSERT INTO dst SELECT 'one';
INSERT INTO dst SELECT 'x', 'y', 'z' UNION ALL SELECT 'p', 'q', 'r';
INSERT INTO dst (b) SELECT 'p', 'q';
INSERT INTO dst (a, b) SELECT 'only';
WITH c AS (SELECT 1 AS k, 2 AS m, 3 AS n) INSERT INTO dst SELECT * FROM c;
INSERT INTO dst (a, c) SELECT 1, 2;
INSERT INTO nowhere SELECT 1;
INSERT INTO dst (b, a) SELECT 'B', 'A';
SELECT a, b FROM dst;
