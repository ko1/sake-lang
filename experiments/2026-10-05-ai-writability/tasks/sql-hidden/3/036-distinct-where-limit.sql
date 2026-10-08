CREATE TABLE visits (person TEXT, place TEXT, yr INTEGER);
INSERT INTO visits VALUES ('jo', 'paris', 2020), ('jo', 'rome', 2021), ('ka', 'paris', 2020), ('ka', 'paris', 2022), ('li', 'oslo', 2021);
SELECT DISTINCT place FROM visits WHERE yr >= 2021 ORDER BY place;
SELECT DISTINCT person, place FROM visits WHERE place <> 'oslo' ORDER BY person, place LIMIT 2;
SELECT DISTINCT yr FROM visits ORDER BY yr LIMIT 2 OFFSET 1;
SELECT ALL place FROM visits WHERE person = 'ka' ORDER BY yr;
SELECT DISTINCT place, count(*) FROM visits GROUP BY person, place ORDER BY 1, 2;
