-- scenario: a support queue, with per-agent workloads, response times and backlog
CREATE TABLE agent (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, team TEXT);
CREATE TABLE ticket (id INTEGER PRIMARY KEY, opened INTEGER NOT NULL, closed INTEGER, agent_id INTEGER, prio TEXT DEFAULT 'low');
INSERT INTO agent (name, team) VALUES ('nia','web'),('oli','web'),('pat','app');
INSERT INTO ticket (opened, closed, agent_id, prio) VALUES (1,4,1,'high'),(2,3,2,'low'),(2,9,1,'low'),(5,6,3,'high'),
  (6,NULL,2,'mid'),(7,8,3,'low'),(8,NULL,NULL,'high'),(9,12,1,'mid');
INSERT INTO ticket (opened, agent_id) VALUES (10, 3);
INSERT INTO agent (name, team) VALUES ('nia', 'app');
-- backlog after each opening: opened so far minus closed by then
SELECT t.id, t.opened, count(*) OVER (ORDER BY t.opened RANGE UNBOUNDED PRECEDING) AS opened_so_far FROM ticket AS t ORDER BY t.id;
SELECT a.name, count(t.id), sum(t.closed - t.opened), rank() OVER (ORDER BY count(t.id) DESC) FROM agent AS a LEFT JOIN ticket AS t ON t.agent_id = a.id
  GROUP BY a.id ORDER BY a.name;
SELECT id, agent_id, row_number() OVER (PARTITION BY agent_id ORDER BY opened, id) FROM ticket WHERE agent_id IS NOT NULL ORDER BY id;
-- time since the agent's previous ticket
SELECT id, agent_id, opened - lag(opened, 1, opened) OVER (PARTITION BY agent_id ORDER BY opened, id) FROM ticket ORDER BY id;
-- each ticket's resolution time against its priority's average
SELECT id, prio, closed - opened AS took, round(avg(closed - opened) OVER (PARTITION BY prio), 2) FROM ticket ORDER BY id;
SELECT prio, count(*), count(closed), dense_rank() OVER (ORDER BY count(*) - count(closed) DESC) FROM ticket GROUP BY prio ORDER BY prio;
CREATE VIEW workload AS SELECT a.team, a.name, count(t.id) AS n FROM agent AS a JOIN ticket AS t ON t.agent_id = a.id GROUP BY a.team, a.name;
SELECT team, name, n, sum(n) OVER (PARTITION BY team), n * 100 / sum(n) OVER () FROM workload ORDER BY team, name;
-- assign the unowned ticket to the least busy agent
UPDATE ticket SET agent_id = (SELECT id FROM (SELECT a.id, row_number() OVER (ORDER BY count(t.id), a.name) AS rn FROM agent AS a
  LEFT JOIN ticket AS t ON t.agent_id = a.id GROUP BY a.id) WHERE rn = 1) WHERE agent_id IS NULL;
SELECT id, agent_id FROM ticket WHERE prio = 'high' ORDER BY id;
SELECT team, name, n, rank() OVER (PARTITION BY team ORDER BY n DESC) FROM workload ORDER BY team, name;
-- tickets opened within 2 time units of each other
SELECT id, opened, count(*) OVER (ORDER BY opened RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING) - 1 AS neighbours FROM ticket ORDER BY id;
SELECT id, cume_dist() OVER (ORDER BY closed - opened) FROM ticket WHERE closed IS NOT NULL ORDER BY id;
UPDATE ticket SET closed = 13 WHERE closed IS NULL;
SELECT closed, count(*), sum(count(*)) OVER (ORDER BY closed) FROM ticket GROUP BY closed ORDER BY closed;
SELECT id, max(closed) OVER (PARTITION BY agent_id ORDER BY opened, id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_done FROM ticket ORDER BY id;
SELECT name FROM agent ORDER BY (SELECT count(*) FROM ticket WHERE agent_id = agent.id) DESC, name LIMIT 1;
