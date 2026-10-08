CREATE TABLE tutors (tid INTEGER, tname TEXT);
CREATE TABLE sessions (tid INTEGER, pupil TEXT, mins INTEGER);
INSERT INTO tutors VALUES (1, 'Ivy'), (2, 'Jon'), (3, 'Kai'), (4, 'Liv');
INSERT INTO sessions VALUES (1, 'a', 30), (1, 'b', 45), (3, 'a', 60), (3, 'c', NULL);
SELECT tname FROM tutors t LEFT JOIN sessions s ON s.tid = t.tid GROUP BY t.tid HAVING count(s.tid) = 0 ORDER BY tname;
SELECT tname, count(s.tid), count(mins), sum(mins) FROM tutors t LEFT JOIN sessions s ON s.tid = t.tid
  GROUP BY tname HAVING count(*) >= 1 ORDER BY tname;
SELECT tname, coalesce(max(mins), 0) AS longest FROM tutors t LEFT JOIN sessions s ON s.tid = t.tid
  GROUP BY t.tid ORDER BY longest DESC, tname;
