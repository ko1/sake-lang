CREATE TABLE logins (usr TEXT, day INTEGER, ip TEXT);
INSERT INTO logins VALUES ('a', 1, 'x'), ('a', 1, 'y'), ('a', 2, 'x'), ('b', 1, 'z'), ('b', 3, 'z'), ('c', 2, NULL);
SELECT usr, count(*), count(DISTINCT day), count(DISTINCT ip) FROM logins GROUP BY usr ORDER BY usr;
SELECT day, count(DISTINCT usr) AS users FROM logins GROUP BY day ORDER BY users DESC, day;
SELECT usr FROM logins GROUP BY usr HAVING count(DISTINCT day) > 1 ORDER BY usr;
SELECT count(DISTINCT usr || day) FROM logins;
