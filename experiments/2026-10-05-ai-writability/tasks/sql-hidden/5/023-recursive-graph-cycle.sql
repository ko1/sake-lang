-- reachability in a graph with a cycle: UNION stops at rows seen before
CREATE TABLE edge (src TEXT, dst TEXT);
INSERT INTO edge VALUES ('a', 'b'), ('b', 'c'), ('c', 'a'), ('c', 'd'), ('e', 'f');
WITH RECURSIVE reach(n) AS (SELECT 'a' UNION SELECT e.dst FROM edge e JOIN reach r ON e.src = r.n) SELECT n FROM reach ORDER BY n;
WITH RECURSIVE reach(n) AS (SELECT 'e' UNION SELECT dst FROM edge, reach WHERE src = n) SELECT count(*) FROM reach;
WITH RECURSIVE walk(n, steps) AS (SELECT 'a', 0 UNION ALL SELECT e.dst, w.steps + 1 FROM edge e JOIN walk w ON e.src = w.n WHERE w.steps < 4) SELECT n, steps FROM walk ORDER BY steps, n;
WITH RECURSIVE reach(n) AS (SELECT 'd' UNION SELECT dst FROM edge JOIN reach ON src = n) SELECT n FROM reach;
