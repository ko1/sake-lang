CREATE TABLE stamps (album INTEGER, country TEXT);
INSERT INTO stamps VALUES (1, 'fr'), (1, 'de'), (1, 'fr'), (2, 'it'), (2, 'it'), (2, NULL), (3, NULL);
SELECT album, group_concat(DISTINCT country ORDER BY country DESC) FROM stamps GROUP BY album ORDER BY album;
SELECT group_concat(DISTINCT country ORDER BY country) FROM stamps;
SELECT count(DISTINCT country), group_concat(DISTINCT upper(country) ORDER BY upper(country)) FROM stamps WHERE album < 3;
SELECT group_concat(DISTINCT album ORDER BY album DESC) FROM stamps WHERE country IS NOT NULL;
