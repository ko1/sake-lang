-- scenario: gym workout log, personal bests, streaks and volume
CREATE TABLE lifter (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE workout (lifter_id INTEGER NOT NULL, wk INTEGER NOT NULL, lift TEXT NOT NULL, kg INTEGER NOT NULL, reps INTEGER DEFAULT 5);
INSERT INTO lifter (name) VALUES ('kay'), ('lou'), ('max');
INSERT INTO workout VALUES (1,1,'squat',60,5),(1,2,'squat',65,5),(1,3,'squat',62,8),(1,4,'squat',70,3),(1,1,'bench',40,5),(1,3,'bench',45,5),
  (2,1,'squat',80,5),(2,2,'squat',80,6),(2,4,'squat',85,4),(3,2,'bench',50,5);
INSERT INTO workout (lifter_id, wk, lift, kg) VALUES (3, 3, 'bench', 52), (3, 4, 'bench', 52.5);
SELECT count(*) FROM workout;
-- personal best so far, and whether this session set a new one
SELECT lifter_id, lift, wk, kg, max(kg) OVER (PARTITION BY lifter_id, lift ORDER BY wk) AS best,
  CASE WHEN kg > coalesce(max(kg) OVER (PARTITION BY lifter_id, lift ORDER BY wk ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) THEN 'pb' ELSE '' END
  FROM workout ORDER BY lifter_id, lift, wk;
-- volume (kg x reps) per week with a running total per lifter
SELECT lifter_id, wk, sum(kg * reps) AS vol, sum(sum(kg * reps)) OVER (PARTITION BY lifter_id ORDER BY wk) FROM workout GROUP BY lifter_id, wk ORDER BY lifter_id, wk;
SELECT l.name, w.lift, max(w.kg), rank() OVER (PARTITION BY w.lift ORDER BY max(w.kg) DESC) FROM workout AS w JOIN lifter AS l ON l.id = w.lifter_id
  GROUP BY l.name, w.lift ORDER BY w.lift, l.name;
-- weeks missed between sessions of a lift
SELECT lifter_id, lift, wk, wk - lag(wk) OVER (PARTITION BY lifter_id, lift ORDER BY wk) - 1 AS missed FROM workout ORDER BY lifter_id, lift, wk;
SELECT lifter_id, lift, wk, kg - first_value(kg) OVER (PARTITION BY lifter_id, lift ORDER BY wk) AS gain FROM workout WHERE lift = 'squat' ORDER BY lifter_id, wk;
-- two-week rolling average weight
SELECT lifter_id, wk, avg(kg) OVER (PARTITION BY lifter_id ORDER BY wk RANGE BETWEEN 1 PRECEDING AND CURRENT ROW) FROM workout WHERE lift = 'squat' ORDER BY lifter_id, wk;
BEGIN;
DELETE FROM workout WHERE kg < 50;
SELECT lifter_id, count(*), ntile(2) OVER (ORDER BY count(*) DESC, lifter_id) FROM workout GROUP BY lifter_id ORDER BY lifter_id;
ROLLBACK;
SELECT lifter_id, count(*), ntile(2) OVER (ORDER BY count(*) DESC, lifter_id) FROM workout GROUP BY lifter_id ORDER BY lifter_id;
ALTER TABLE workout ADD COLUMN rpe INTEGER;
UPDATE workout SET rpe = 9 WHERE reps <= 4;
SELECT lifter_id, wk, rpe, count(rpe) OVER (PARTITION BY lifter_id ORDER BY wk, lift) FROM workout WHERE lift = 'squat' ORDER BY lifter_id, wk;
SELECT DISTINCT lift, last_value(lifter_id) OVER (PARTITION BY lift ORDER BY kg, wk ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM workout ORDER BY lift;
SELECT name FROM lifter WHERE id IN (SELECT lifter_id FROM (SELECT lifter_id, dense_rank() OVER (ORDER BY kg DESC) AS dr FROM workout WHERE lift = 'squat') WHERE dr <= 2) ORDER BY name;
SELECT lifter_id, wk, lift, nth_value(kg, 2) OVER (PARTITION BY lifter_id ORDER BY wk, lift) FROM workout WHERE lifter_id = 1 ORDER BY wk, lift;
