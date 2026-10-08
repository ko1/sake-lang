-- A clinic: doctors, patients and appointments.
CREATE TABLE doctors (did INTEGER PRIMARY KEY, dname TEXT, specialty TEXT);
CREATE TABLE patients (pid INTEGER PRIMARY KEY, pname TEXT NOT NULL, born INTEGER);
CREATE TABLE appts (did INTEGER NOT NULL, pid INTEGER NOT NULL, day INTEGER, fee REAL, UNIQUE (did, day));
INSERT INTO doctors VALUES (1, 'Dr Ek', 'heart'), (2, 'Dr Lind', 'skin'), (3, 'Dr Moe', 'heart');
INSERT INTO patients VALUES (1, 'Anna', 1950), (2, 'Bert', 1985), (3, 'Cleo', 2001), (4, 'Dag', 1990), (5, 'Eva', 1970);
INSERT INTO appts VALUES (1, 1, 1, 100.0), (1, 2, 2, 150.0), (2, 1, 1, 60.5), (3, 3, 1, 120.0), (2, 4, 3, 60.5),
  (3, 1, 2, 120.0);
INSERT INTO appts VALUES (2, 2, 2, 60.5), (1, 3, 1, 90.0);
INSERT INTO appts (did, day) VALUES (2, 9);
-- schedule by day
SELECT day, dname, pname FROM appts JOIN doctors USING (did) JOIN patients USING (pid) ORDER BY day, dname;
-- income per specialty
SELECT specialty, sum(fee), count(*) FROM doctors JOIN appts USING (did) GROUP BY specialty ORDER BY specialty;
-- patients seen by every heart doctor
SELECT pname FROM patients p WHERE NOT EXISTS (SELECT 1 FROM doctors d WHERE specialty = 'heart'
  AND NOT EXISTS (SELECT 1 FROM appts a WHERE a.did = d.did AND a.pid = p.pid)) ORDER BY pname;
-- the oldest patient of each doctor
SELECT dname, (SELECT pname FROM patients JOIN appts USING (pid) WHERE appts.did = doctors.did ORDER BY born LIMIT 1)
  FROM doctors ORDER BY did;
-- patients with no appointment
SELECT pname FROM patients LEFT JOIN appts USING (pid) WHERE did IS NULL ORDER BY pname;
-- fee above the doctor's average
SELECT dname, pname, fee FROM appts a JOIN doctors USING (did) JOIN patients USING (pid)
  WHERE fee > (SELECT avg(fee) FROM appts WHERE did = a.did) ORDER BY dname, pname;
DELETE FROM appts WHERE pid IN (SELECT pid FROM patients WHERE born < 1960) AND did IN (SELECT did FROM doctors WHERE specialty = 'skin');
SELECT dname, count(pid) FROM doctors LEFT JOIN appts USING (did) GROUP BY did ORDER BY did;
SELECT pname FROM patients JOIN appts USING (pid) JOIN doctors USING (did) WHERE dname = 'Dr Ek' ORDER BY day;
SELECT day FROM appts JOIN doctors ON doctors.did = appts.did WHERE did = 1;
SELECT p.pname FROM patients AS p WHERE p.born > (SELECT patients.born FROM patients WHERE pname = 'Bert') ORDER BY p.pname;
SELECT pname FROM patients WHERE pid IN (SELECT pid FROM appts WHERE fee > 100) ORDER BY pname;
