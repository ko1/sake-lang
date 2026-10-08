-- Subqueries in HAVING and in the result of an aggregate query.
CREATE TABLE visits (page TEXT, ms INTEGER);
INSERT INTO visits VALUES ('home', 120), ('home', 80), ('about', 300), ('blog', 90), ('blog', 110), ('blog', 100);
SELECT page, count(*) FROM visits GROUP BY page
  HAVING count(*) >= (SELECT count(*) FROM visits WHERE page = 'home') ORDER BY page;
SELECT page, avg(ms) FROM visits GROUP BY page HAVING avg(ms) > (SELECT avg(ms) FROM visits) ORDER BY page;
SELECT page, count(*) * 100 / (SELECT count(*) FROM visits) AS pct FROM visits GROUP BY page ORDER BY pct DESC, page;
SELECT page, (SELECT max(ms) FROM visits v2 WHERE v2.page = visits.page) FROM visits GROUP BY page ORDER BY page;
