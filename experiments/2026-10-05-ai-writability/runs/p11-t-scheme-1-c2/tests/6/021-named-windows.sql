-- WINDOW name AS (...) and OVER name
CREATE TABLE lap (racer TEXT, lap INTEGER, secs INTEGER);
INSERT INTO lap VALUES ('kim',1,62),('kim',2,60),('kim',3,61),('lee',1,65),('lee',2,59),('lee',3,63);
SELECT racer, lap, sum(secs) OVER w, row_number() OVER w, lag(secs) OVER w
  FROM lap WINDOW w AS (PARTITION BY racer ORDER BY lap) ORDER BY racer, lap;
SELECT racer, lap, rank() OVER fast, min(secs) OVER all_laps
  FROM lap WINDOW fast AS (ORDER BY secs), all_laps AS (PARTITION BY lap) ORDER BY racer, lap;
-- names are case-insensitive
SELECT racer, lap, count(*) OVER Win FROM lap WINDOW wIN AS (ORDER BY lap, racer ROWS 1 PRECEDING) ORDER BY racer, lap;
SELECT racer, max(secs) OVER w FROM lap WHERE lap = 2 WINDOW w AS () ORDER BY racer;
