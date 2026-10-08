CREATE TABLE ev (ts INTEGER, kind TEXT);
INSERT INTO ev VALUES (61, 'click'), (59, 'view'), (125, 'click'), (130, 'click'), (3, 'view');
SELECT ts / 60 AS minute, count(*) FROM ev GROUP BY 1 ORDER BY 1;
SELECT kind, ts / 60, count(*) FROM ev GROUP BY 2, 1 ORDER BY 2, 1;
SELECT upper(kind), max(ts) FROM ev GROUP BY 1 ORDER BY 2;
SELECT kind, count(*) FROM ev GROUP BY 1 HAVING count(*) = 2;
