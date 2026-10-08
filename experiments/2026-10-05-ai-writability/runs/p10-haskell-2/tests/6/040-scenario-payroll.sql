-- scenario: payroll by department with salary bands, raises and history
CREATE TABLE dept (code TEXT PRIMARY KEY, title TEXT);
CREATE TABLE staff (id INTEGER PRIMARY KEY, name TEXT, code TEXT, pay INTEGER NOT NULL, hired INTEGER);
INSERT INTO dept VALUES ('eng', 'engineering'), ('ops', 'operations'), ('fin', 'finance');
INSERT INTO staff (name, code, pay, hired) VALUES ('ana','eng',5200,2019),('raj','eng',6100,2016),('lu','eng',4800,2022),
  ('mo','ops',3900,2018),('kit','ops',4100,2020),('zoe','fin',5500,2015),('ned','fin',5500,2021);
SELECT d.title, s.name, s.pay, rank() OVER (PARTITION BY d.code ORDER BY s.pay DESC) FROM staff AS s JOIN dept AS d ON d.code = s.code ORDER BY d.title, s.pay DESC, s.name;
SELECT code, name, pay - avg(pay) OVER (PARTITION BY code) FROM staff ORDER BY code, name;
SELECT code, name, round(pay * 1.0 / sum(pay) OVER (PARTITION BY code), 3) FROM staff ORDER BY code, name;
-- seniority order within each department
SELECT code, name, row_number() OVER (PARTITION BY code ORDER BY hired) AS senior FROM staff ORDER BY code, senior;
-- pay bands across the company
SELECT name, ntile(3) OVER (ORDER BY pay, hired) AS band FROM staff ORDER BY band, pay, name;
SELECT code, count(*), sum(pay), sum(sum(pay)) OVER (ORDER BY sum(pay) DESC) AS cum FROM staff GROUP BY code ORDER BY cum;
-- a raise for everyone hired before 2019, kept in a history table
CREATE TABLE history (staff_id INTEGER, old_pay INTEGER, new_pay INTEGER);
INSERT INTO history SELECT id, pay, pay + 300 FROM staff WHERE hired < 2019;
UPDATE staff SET pay = pay + 300 WHERE hired < 2019;
SELECT s.name, h.old_pay, h.new_pay, sum(h.new_pay - h.old_pay) OVER (ORDER BY s.name) FROM history AS h JOIN staff AS s ON s.id = h.staff_id ORDER BY s.name;
SELECT code, name, pay, rank() OVER (PARTITION BY code ORDER BY pay DESC) AS r FROM staff WHERE code = 'fin' ORDER BY r, name;
SELECT name, pay, lag(name) OVER (ORDER BY pay DESC, name) AS above, lead(name) OVER (ORDER BY pay DESC, name) AS below FROM staff ORDER BY pay DESC, name;
SELECT code, name, cume_dist() OVER (PARTITION BY code ORDER BY pay) FROM staff ORDER BY code, name;
-- departments by headcount, as a CTE
WITH hc AS (SELECT code, count(*) AS n FROM staff GROUP BY code)
SELECT d.title, hc.n, dense_rank() OVER (ORDER BY hc.n DESC) FROM hc JOIN dept AS d USING (code) ORDER BY d.title;
SELECT name, max(pay) OVER (ORDER BY hired ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) FROM staff ORDER BY hired;
DELETE FROM staff WHERE name = 'lu';
SELECT code, name, percent_rank() OVER (PARTITION BY code ORDER BY pay) FROM staff ORDER BY code, name;
SELECT code, last_value(name) OVER (PARTITION BY code ORDER BY hired ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS newest
  FROM staff GROUP BY code, name ORDER BY code, name;
