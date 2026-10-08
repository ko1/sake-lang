CREATE TABLE e (n INTEGER, t TEXT);
SELECT count(*), count(n), sum(n), total(n), avg(n) FROM e;
SELECT min(n), max(t), group_concat(t), group_concat(t, '-') FROM e;
SELECT count(DISTINCT n), sum(DISTINCT n) FROM e;
SELECT typeof(sum(n)), typeof(total(n)), typeof(count(n)) FROM e;
