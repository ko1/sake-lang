CREATE TABLE an (v INTEGER);
INSERT INTO an VALUES (6), (NULL), (3);
SELECT count(*), sum(1), total(2), group_concat('a');
SELECT sum(v) / count(v) FROM an;
SELECT sum(v) / count(v), sum(v) % 4, count(*) / 0, max(v) || min(v) FROM an;
SELECT sum(v) * 1.0 / count(*) FROM an;
