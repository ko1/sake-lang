-- two aliases of one table each have their own rowid
CREATE TABLE step (name TEXT);
INSERT INTO step VALUES ('mix'), ('bake'), ('cool'), ('serve');
SELECT p.name, n.name FROM step AS p JOIN step AS n ON n.rowid = p.rowid + 1 ORDER BY p.rowid;
SELECT count(*) FROM step a, step b WHERE a.oid < b.oid;
