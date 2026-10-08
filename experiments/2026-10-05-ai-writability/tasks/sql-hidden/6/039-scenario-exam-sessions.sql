-- scenario: an exam timetable, room usage and candidate loads
CREATE TABLE room (name TEXT PRIMARY KEY, seats INTEGER NOT NULL);
CREATE TABLE exam (code TEXT PRIMARY KEY, room TEXT, day INTEGER NOT NULL, slot INTEGER NOT NULL, mins INTEGER DEFAULT 120);
CREATE TABLE sitting (cand TEXT, code TEXT, UNIQUE (cand, code));
INSERT INTO room VALUES ('hall', 200), ('lab', 30), ('aud', 80);
INSERT INTO exam VALUES ('m1','hall',1,1,180),('p1','lab',1,2,90),('c1','aud',2,1,120),('m2','hall',2,2,150),('b1','aud',3,1,60),('e1','hall',3,1,120);
INSERT INTO exam (code, room, day, slot) VALUES ('h1', 'lab', 4, 1);
INSERT INTO sitting VALUES ('ann','m1'),('ann','p1'),('ann','m2'),('ben','m1'),('ben','c1'),('cat','c1'),('cat','b1'),('cat','e1'),('cat','h1'),('dan','m1');
INSERT INTO sitting VALUES ('dan','m1');
-- exam order within each day, and the next exam in the same room
SELECT code, day, slot, row_number() OVER (PARTITION BY day ORDER BY slot, code) FROM exam ORDER BY day, slot, code;
SELECT room, code, lead(code, 1, '-') OVER (PARTITION BY room ORDER BY day, slot) FROM exam ORDER BY room, day, slot;
-- room usage in minutes, with share of the total
SELECT room, sum(mins), sum(mins) * 100 / sum(sum(mins)) OVER () AS pct, rank() OVER (ORDER BY sum(mins) DESC) FROM exam GROUP BY room ORDER BY room;
-- candidates per exam and fill rate of the room
SELECT e.code, count(s.cand) AS n, r.seats, rank() OVER (ORDER BY count(s.cand) DESC) FROM exam AS e JOIN room AS r ON r.name = e.room
  LEFT JOIN sitting AS s ON s.code = e.code GROUP BY e.code ORDER BY e.code;
-- each candidate's exams in order, and the days between consecutive ones
SELECT s.cand, e.code, e.day - lag(e.day) OVER (PARTITION BY s.cand ORDER BY e.day, e.slot, e.code) AS gap FROM sitting AS s JOIN exam AS e USING (code) ORDER BY s.cand, e.day, e.slot, e.code;
-- clashes: two exams of one candidate in the same day and slot
SELECT cand, day, slot FROM (SELECT s.cand, e.day, e.slot, count(*) OVER (PARTITION BY s.cand, e.day, e.slot) AS k FROM sitting AS s JOIN exam AS e ON e.code = s.code)
  WHERE k > 1 GROUP BY cand, day, slot ORDER BY cand;
SELECT cand, count(*) AS n, ntile(2) OVER (ORDER BY count(*) DESC, cand) FROM sitting GROUP BY cand ORDER BY cand;
-- move the clashing exam to the next free slot
UPDATE exam SET slot = 2 WHERE code = 'e1';
SELECT cand, day, slot FROM (SELECT s.cand, e.day, e.slot, count(*) OVER (PARTITION BY s.cand, e.day, e.slot) AS k FROM sitting AS s JOIN exam AS e ON e.code = s.code)
  WHERE k > 1 ORDER BY cand;
SELECT day, count(*), sum(count(*)) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) FROM exam GROUP BY day ORDER BY day;
SELECT code, mins, dense_rank() OVER (ORDER BY mins DESC), percent_rank() OVER (ORDER BY mins) FROM exam ORDER BY code;
SELECT cand, group_concat(code, ' ') OVER (PARTITION BY cand ORDER BY code ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM sitting WHERE cand IN ('ann', 'cat') GROUP BY cand, code ORDER BY cand, code LIMIT 5;
DELETE FROM sitting WHERE cand = 'cat' AND code = 'h1';
SELECT DISTINCT cand, last_value(code) OVER (PARTITION BY cand ORDER BY code RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM sitting ORDER BY cand;
SELECT code, room, first_value(code) OVER (PARTITION BY room ORDER BY mins DESC, code) FROM exam ORDER BY code;
