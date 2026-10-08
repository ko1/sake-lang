SELECT substr('abcdef', -2), substr('abcdef', -6), substr('abcdef', -10), substr('abcdef', -10, 6);
SELECT substr('abcdef', -8, 4), substr('abcdef', 4, -2), substr('abcdef', 3, -5), substr('abcdef', -2, -2);
SELECT substr('abcdef', 0, -1), substr('abcdef', 7, -3), substr('abcdef', 2, -1);
CREATE TABLE f (name TEXT);
INSERT INTO f VALUES ('report.pdf'), ('img.png'), ('notes.txt');
SELECT substr(name, -3) || ':' || substr(name, 1, length(name) - 4) FROM f ORDER BY name;
