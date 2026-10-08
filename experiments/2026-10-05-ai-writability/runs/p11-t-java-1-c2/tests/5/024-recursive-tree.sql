-- walking a hierarchy with a recursive cte joined to a table
CREATE TABLE node (id INTEGER PRIMARY KEY, parent INTEGER, name TEXT);
INSERT INTO node VALUES (1, NULL, 'root'), (2, 1, 'etc'), (3, 1, 'usr'), (4, 3, 'bin'), (5, 3, 'lib'), (6, 4, 'x11'), (7, 2, 'ssh');
WITH RECURSIVE sub(id, depth) AS (SELECT id, 0 FROM node WHERE name = 'usr' UNION ALL SELECT node.id, sub.depth + 1 FROM node JOIN sub ON node.parent = sub.id) SELECT n.name, s.depth FROM sub s JOIN node n ON n.id = s.id ORDER BY s.depth, n.name;
WITH RECURSIVE up(id, path) AS (SELECT parent, name FROM node WHERE name = 'x11' UNION ALL SELECT node.parent, node.name || '/' || up.path FROM up JOIN node ON node.id = up.id) SELECT path FROM up WHERE id IS NULL;
WITH RECURSIVE anc(id) AS (SELECT parent FROM node WHERE id = 6 UNION ALL SELECT parent FROM node, anc WHERE node.id = anc.id AND node.parent IS NOT NULL) SELECT count(*) FROM anc;
