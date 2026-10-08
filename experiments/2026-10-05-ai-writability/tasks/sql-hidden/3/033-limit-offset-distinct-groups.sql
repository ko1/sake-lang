CREATE TABLE clicks (btn TEXT, user INTEGER);
INSERT INTO clicks VALUES ('ok', 1), ('ok', 2), ('cancel', 1), ('help', 3), ('ok', 1), ('help', 3), ('back', 2);
SELECT btn, count(*) AS n FROM clicks GROUP BY btn ORDER BY n DESC, btn LIMIT 3;
SELECT btn, count(DISTINCT user) FROM clicks GROUP BY btn ORDER BY btn LIMIT 2 OFFSET 1;
SELECT DISTINCT user FROM clicks ORDER BY user DESC LIMIT 1 OFFSET 1;
SELECT DISTINCT btn, user FROM clicks ORDER BY btn, user LIMIT -1 OFFSET 3;
SELECT count(*) FROM clicks GROUP BY btn ORDER BY 1 DESC LIMIT 1 OFFSET -2;
