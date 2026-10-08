CREATE TABLE visits (day INTEGER, page TEXT);
INSERT INTO visits VALUES (1, 'home'), (1, 'home'), (1, 'about'), (2, 'home'), (2, NULL);
SELECT group_concat(DISTINCT page ORDER BY page) FROM visits;
SELECT group_concat(DISTINCT page) FROM visits WHERE day = 2;
SELECT day, group_concat(DISTINCT page ORDER BY page DESC) FROM visits GROUP BY day ORDER BY day;
SELECT group_concat(DISTINCT day) FROM visits WHERE page = 'about';
