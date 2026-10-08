CREATE TABLE raw (s TEXT);
INSERT INTO raw VALUES ('12'), ('7.9'), ('3x'), ('abc'), (NULL);
SELECT sum(CAST(s AS INTEGER)), typeof(sum(CAST(s AS INTEGER))) FROM raw;
SELECT sum(CAST(s AS REAL)), max(CAST(s AS REAL)) FROM raw;
SELECT max(s), max(CAST(s AS INTEGER)) FROM raw;
SELECT CAST(avg(CAST(s AS INTEGER)) AS INTEGER), CAST(count(*) AS TEXT) || ' rows' FROM raw;
SELECT group_concat(CAST(s AS INTEGER), '+') FROM raw WHERE s = '12';
