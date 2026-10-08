-- How the columns of a subquery source are named.
CREATE TABLE cars (make TEXT, model TEXT, hp INTEGER);
INSERT INTO cars VALUES ('vw', 'golf', 110), ('vw', 'polo', 75), ('fiat', 'uno', 45);
SELECT d.make, d.model FROM (SELECT cars.make, model FROM cars WHERE hp > 50) d ORDER BY d.model;
SELECT d.power FROM (SELECT hp AS power FROM cars) AS d ORDER BY d.power;
SELECT d.hp FROM (SELECT hp AS power FROM cars) AS d;
SELECT power FROM (SELECT hp AS power FROM cars) WHERE hp > 50;
SELECT x.n, y.n FROM (SELECT count(*) AS n FROM cars) x, (SELECT count(DISTINCT make) AS n FROM cars) y;
SELECT n FROM (SELECT count(*) AS n FROM cars) x, (SELECT count(DISTINCT make) AS n FROM cars) y;
SELECT d.*, e.* FROM (SELECT make AS m FROM cars WHERE hp < 50) d, (SELECT max(hp) AS top FROM cars) e;
