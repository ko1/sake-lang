-- INSERT ... SELECT converts and checks every row; one failure inserts nothing
CREATE TABLE raw (v TEXT);
CREATE TABLE num (n INTEGER NOT NULL UNIQUE);
INSERT INTO raw VALUES ('10'), (' 20 '), ('3.0');
INSERT INTO num SELECT v FROM raw;
SELECT n, typeof(n) FROM num ORDER BY n;
INSERT INTO raw VALUES ('oops');
INSERT INTO num SELECT v || '1' FROM raw WHERE v <> '3.0';
SELECT count(*) FROM num;
INSERT INTO num SELECT 40 UNION ALL SELECT 20;
INSERT INTO num SELECT 50 UNION ALL SELECT NULL;
INSERT INTO num SELECT 7.5;
SELECT count(*) FROM num;
