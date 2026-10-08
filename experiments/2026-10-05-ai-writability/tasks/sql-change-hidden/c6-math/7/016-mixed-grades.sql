-- grading: scores rounded up per student, statistics over groups and windows
CREATE TABLE score (student TEXT, course TEXT, pts REAL);
INSERT INTO score VALUES
  ('amy', 'math', 71.2), ('amy', 'art', 88.0), ('ben', 'math', 64.5),
  ('ben', 'art', 90.1), ('cal', 'math', 99.9), ('cal', 'art', 55.5);
SELECT student, sum(ceil(pts)) AS total, max(floor(pts)) FROM score GROUP BY student ORDER BY total DESC, student;
SELECT course, sqrt(sum(pow(pts - 75, 2)) / count(*)) AS spread FROM score GROUP BY course ORDER BY course;
SELECT student, course, ceil(pts) AS c,
       rank() OVER (PARTITION BY course ORDER BY ceil(pts) DESC) AS place
  FROM score ORDER BY course, place;
SELECT trunc(pts / 10) AS decile, count(*) FROM score GROUP BY decile ORDER BY decile DESC;
