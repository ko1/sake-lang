CREATE TABLE z (v INTEGER);
INSERT INTO z VALUES (2), (4);
SELECT COUNT(*), Sum(v), AVG(v), Total(v), MIN(v), mAx(v), GROUP_CONCAT(v ORDER BY v DESC) FROM z;
SELECT count(DISTINCT v), COUNT(distinct v) FROM z;
SELECT sum(v) AS S FROM z;
