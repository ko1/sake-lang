-- Concert tickets: events, venues, buyers.
CREATE TABLE venues (vid INTEGER PRIMARY KEY, vname TEXT, capacity INTEGER NOT NULL);
CREATE TABLE events (eid INTEGER PRIMARY KEY, vid INTEGER, act TEXT, day INTEGER, price INTEGER);
CREATE TABLE tickets (eid INTEGER, buyer TEXT, qty INTEGER NOT NULL);
INSERT INTO venues VALUES (1, 'Hall', 3), (2, 'Club', 2), (3, 'Park', 100);
INSERT INTO events VALUES (10, 1, 'Ane', 1, 50), (11, 2, 'Bo', 1, 20), (12, 1, 'Cid', 2, 40), (13, 3, 'Ane', 5, 30);
INSERT INTO tickets VALUES (10, 'x', 2), (10, 'y', 1), (11, 'x', 3), (12, 'z', 1), (13, 'y', 4), (13, 'z', 1);
INSERT INTO tickets VALUES (12, 'w', NULL);
-- sold versus capacity
SELECT act, day, vname, (SELECT sum(qty) FROM tickets t WHERE t.eid = e.eid) AS sold, capacity
  FROM events e JOIN venues USING (vid) ORDER BY eid;
-- oversold events
SELECT eid FROM events e JOIN venues v ON v.vid = e.vid WHERE capacity < (SELECT sum(qty) FROM tickets WHERE eid = e.eid);
-- revenue per act
SELECT act, sum(qty * price) FROM events JOIN tickets USING (eid) GROUP BY act ORDER BY act;
-- buyers who went to every show of Ane
SELECT DISTINCT buyer FROM tickets t WHERE NOT EXISTS (SELECT 1 FROM events e WHERE act = 'Ane'
  AND e.eid NOT IN (SELECT eid FROM tickets WHERE buyer = t.buyer)) ORDER BY buyer;
-- venues without events on day 1
SELECT vname FROM venues v LEFT JOIN events e ON e.vid = v.vid AND e.day = 1 WHERE e.eid IS NULL ORDER BY vname;
-- each buyer's spending and favourite act by quantity
SELECT buyer, sum(qty * price), (SELECT act FROM events JOIN tickets t2 USING (eid) WHERE t2.buyer = t1.buyer
  GROUP BY act ORDER BY sum(qty) DESC, act LIMIT 1) FROM tickets t1 JOIN events USING (eid) GROUP BY buyer ORDER BY buyer;
-- move Bo to the Park
UPDATE events SET vid = (SELECT vid FROM venues WHERE vname = 'Park') WHERE act = 'Bo';
SELECT eid, vname FROM events JOIN venues USING (vid) ORDER BY eid;
SELECT act FROM events JOIN tickets USING (eid) WHERE buyer = 'x' AND eid = 11;
SELECT eid FROM events JOIN tickets ON tickets.eid = events.eid WHERE buyer = 'z';
SELECT v.* FROM venues v WHERE vid NOT IN (SELECT vid FROM events);
SELECT venues.vname FROM venues v;
SELECT buyer, count(DISTINCT vid) FROM tickets JOIN events USING (eid) GROUP BY buyer ORDER BY buyer;
