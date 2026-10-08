-- An ORDER BY number or alias has the result column's collation, and may take its own COLLATE.
CREATE TABLE crew (id INTEGER, nick TEXT COLLATE NOCASE, real TEXT);
INSERT INTO crew VALUES (1, 'ace', 'Ace'), (2, 'Bolt', 'bolt'), (3, 'CYD', 'Cyd'), (4, 'bix', 'Bix');
SELECT nick, id FROM crew ORDER BY 1;
SELECT nick AS n FROM crew ORDER BY n DESC;
SELECT real FROM crew ORDER BY 1;
SELECT real FROM crew ORDER BY 1 COLLATE NOCASE;
SELECT real AS r FROM crew ORDER BY r COLLATE NOCASE DESC;
SELECT nick || '' AS plain FROM crew ORDER BY plain;
