CREATE TABLE p (name TEXT, h INTEGER, team TEXT);
INSERT INTO p VALUES ('ari',180,'x'),('bex',165,'y'),('col',172,'x'),('dax',190,'y'),('eon',158,'x');
SELECT name FROM p ORDER BY rank() OVER (ORDER BY h);
SELECT name FROM p ORDER BY ntile(2) OVER (ORDER BY h DESC), name DESC;
SELECT name, team FROM p ORDER BY count(*) OVER (PARTITION BY team) DESC, lag(h, 1, 0) OVER (PARTITION BY team ORDER BY h);
SELECT name FROM p ORDER BY h - lag(h, 1, h) OVER (ORDER BY h) DESC, name LIMIT 2;
SELECT name, h FROM p WHERE team = 'x' ORDER BY max(h) OVER () - h;
