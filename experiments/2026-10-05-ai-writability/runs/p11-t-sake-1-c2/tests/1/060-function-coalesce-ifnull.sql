SELECT coalesce(NULL, 2), coalesce(1, 2), coalesce(NULL, NULL);
SELECT coalesce(NULL, NULL, NULL, 'last'), coalesce(NULL, 0, 1);
SELECT ifnull(NULL, 'x'), ifnull('y', 'x'), ifnull(NULL, NULL);
SELECT typeof(coalesce(NULL, 1.5)), COALESCE(NULL, 'up');
CREATE TABLE t (id INTEGER, nick TEXT, name TEXT);
INSERT INTO t VALUES (1, 'Bo', 'Robert'), (2, NULL, 'Alice'), (3, NULL, NULL);
SELECT id, coalesce(nick, name, '?') FROM t ORDER BY id;
SELECT id, ifnull(nick, '-') FROM t ORDER BY id;
SELECT coalesce(nick, name) AS shown FROM t ORDER BY shown;
