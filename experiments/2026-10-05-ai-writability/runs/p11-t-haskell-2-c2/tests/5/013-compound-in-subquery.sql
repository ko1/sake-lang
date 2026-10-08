-- compound selects inside IN, EXISTS and scalar subqueries
CREATE TABLE users (id INTEGER, name TEXT);
CREATE TABLE admins (uid INTEGER);
CREATE TABLE owners (uid INTEGER);
INSERT INTO users VALUES (1, 'ann'), (2, 'ben'), (3, 'cat'), (4, 'dan');
INSERT INTO admins VALUES (1), (3);
INSERT INTO owners VALUES (3), (4);
SELECT name FROM users WHERE id IN (SELECT uid FROM admins UNION SELECT uid FROM owners) ORDER BY name;
SELECT name FROM users WHERE id IN (SELECT uid FROM admins INTERSECT SELECT uid FROM owners);
SELECT name FROM users WHERE id NOT IN (SELECT uid FROM admins UNION ALL SELECT uid FROM owners) ORDER BY name;
SELECT name FROM users u WHERE EXISTS (SELECT uid FROM admins WHERE uid = u.id EXCEPT SELECT uid FROM owners) ORDER BY name;
SELECT (SELECT uid FROM admins UNION SELECT uid FROM owners ORDER BY 1 DESC LIMIT 1);
SELECT (SELECT uid FROM admins EXCEPT SELECT uid FROM admins);
