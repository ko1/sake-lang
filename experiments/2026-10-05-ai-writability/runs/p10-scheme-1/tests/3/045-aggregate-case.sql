CREATE TABLE tickets (id INTEGER PRIMARY KEY, status TEXT, prio INTEGER);
INSERT INTO tickets (status, prio) VALUES ('open', 1), ('closed', 2), ('open', 3), ('open', 1), ('closed', 1);
SELECT sum(CASE WHEN status = 'open' THEN 1 ELSE 0 END), sum(CASE status WHEN 'closed' THEN 1 END) FROM tickets;
SELECT count(CASE WHEN prio = 1 THEN 1 END) FROM tickets;
SELECT prio, group_concat(CASE WHEN status = 'open' THEN 'o' ELSE 'c' END, '' ORDER BY id) FROM tickets GROUP BY prio ORDER BY prio;
SELECT CASE WHEN count(*) > 4 THEN 'busy' ELSE 'calm' END FROM tickets;
