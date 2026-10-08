-- SELECT DISTINCT removes rows equal under each result column's collation.
CREATE TABLE tags (id INTEGER, t TEXT COLLATE NOCASE, raw TEXT, pad TEXT COLLATE RTRIM);
INSERT INTO tags VALUES (1, 'SQL', 'SQL', 'x'), (2, 'sql', 'sql', 'x '), (3, 'Db', 'Db', 'y'),
  (4, 'DB', 'DB', 'x  '), (5, 'sql', 'sql', 'y');
SELECT count(*) FROM (SELECT DISTINCT t FROM tags);
SELECT count(*) FROM (SELECT DISTINCT raw FROM tags);
SELECT count(*) FROM (SELECT DISTINCT raw COLLATE NOCASE FROM tags);
SELECT count(*) FROM (SELECT DISTINCT pad FROM tags);
SELECT count(*) FROM (SELECT DISTINCT t, pad FROM tags);
SELECT DISTINCT lower(t) FROM tags ORDER BY 1;
SELECT DISTINCT length(pad) FROM tags ORDER BY 1;
