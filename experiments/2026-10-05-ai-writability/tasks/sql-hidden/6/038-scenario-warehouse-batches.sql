-- scenario: production batches, defect rates and quality bands per line
CREATE TABLE line (code TEXT PRIMARY KEY, site TEXT NOT NULL);
CREATE TABLE batch (id INTEGER PRIMARY KEY, code TEXT NOT NULL, shift INTEGER NOT NULL, made INTEGER NOT NULL, bad INTEGER NOT NULL DEFAULT 0);
INSERT INTO line VALUES ('l1','north'),('l2','north'),('l3','south');
INSERT INTO batch (code, shift, made, bad) VALUES ('l1',1,200,4),('l1',2,180,9),('l1',3,220,2),('l2',1,150,15),('l2',2,160,8),
  ('l3',1,300,3),('l3',2,310,6),('l3',3,290,29),('l3',4,305,0);
INSERT INTO batch (code, shift, made) VALUES ('l2', 3, 170);
INSERT INTO batch (code, shift) VALUES ('l1', 4);
SELECT code, shift, made, bad, round(100.0 * bad / made, 2) AS pct FROM batch ORDER BY code, shift;
SELECT code, shift, sum(bad) OVER (PARTITION BY code ORDER BY shift) * 1000 / sum(made) OVER (PARTITION BY code ORDER BY shift) AS ppk FROM batch ORDER BY code, shift;
-- quality band by defect rate, across all batches
SELECT id, ntile(3) OVER (ORDER BY 1.0 * bad / made, id) AS band FROM batch ORDER BY id;
SELECT code, shift, rank() OVER (ORDER BY 1.0 * bad / made DESC) FROM batch ORDER BY code, shift;
-- the worst batch of each site
SELECT site, code, shift FROM (SELECT l.site, b.code, b.shift, row_number() OVER (PARTITION BY l.site ORDER BY b.bad * 1.0 / b.made DESC) AS rn
  FROM batch AS b JOIN line AS l USING (code)) WHERE rn = 1 ORDER BY site;
SELECT l.site, sum(b.made), sum(b.bad), dense_rank() OVER (ORDER BY sum(b.bad) * 1.0 / sum(b.made)) FROM batch AS b JOIN line AS l ON l.code = b.code GROUP BY l.site ORDER BY l.site;
-- change in output from the previous shift on the same line
SELECT code, shift, made - lag(made, 1, made) OVER (PARTITION BY code ORDER BY shift) FROM batch ORDER BY code, shift;
SELECT code, shift, lead(bad, 1, -1) OVER (PARTITION BY code ORDER BY shift) FROM batch ORDER BY code, shift;
-- lines whose latest shift is their best
WITH latest AS (SELECT code, shift, bad, last_value(shift) OVER (PARTITION BY code ORDER BY shift RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastshift,
  min(bad) OVER (PARTITION BY code) AS least FROM batch)
SELECT code FROM latest WHERE shift = lastshift AND bad = least ORDER BY code;
-- a recount moves defects between batches, all or nothing
BEGIN;
UPDATE batch SET bad = bad - 5 WHERE code = 'l3' AND shift = 3;
UPDATE batch SET bad = bad + 5 WHERE code = 'l3' AND shift = 4;
COMMIT;
SELECT code, shift, bad, max(bad) OVER (PARTITION BY code ORDER BY shift ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM batch WHERE code = 'l3' ORDER BY shift;
SELECT shift, sum(made), avg(sum(made)) OVER (ORDER BY shift ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) FROM batch GROUP BY shift ORDER BY shift;
SELECT code, count(*), sum(count(*)) OVER () FROM batch GROUP BY code ORDER BY code;
SELECT code, total(bad) OVER (PARTITION BY code), percent_rank() OVER (PARTITION BY code ORDER BY made) FROM batch WHERE made > 0 ORDER BY code, shift;
SELECT DISTINCT code, cume_dist() OVER (ORDER BY code) FROM batch ORDER BY code;
