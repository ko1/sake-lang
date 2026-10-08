-- Airports and flights: the same table joined twice under aliases.
CREATE TABLE airports (code TEXT PRIMARY KEY, city TEXT, country TEXT);
CREATE TABLE flights (fno TEXT PRIMARY KEY, src TEXT NOT NULL, dst TEXT NOT NULL, mins INTEGER, seats INTEGER);
CREATE TABLE bookings (fno TEXT, pax TEXT);
INSERT INTO airports VALUES ('OSL', 'Oslo', 'NO'), ('BGO', 'Bergen', 'NO'), ('CPH', 'Copenhagen', 'DK'),
  ('ARN', 'Stockholm', 'SE'), ('TOS', 'Tromso', 'NO');
INSERT INTO flights VALUES ('F1', 'OSL', 'BGO', 50, 3), ('F2', 'BGO', 'OSL', 55, 2), ('F3', 'OSL', 'CPH', 70, 2),
  ('F4', 'CPH', 'ARN', 65, 1), ('F5', 'ARN', 'OSL', 60, 2);
INSERT INTO bookings VALUES ('F1', 'ann'), ('F1', 'bob'), ('F3', 'ann'), ('F4', 'ann'), ('F4', 'cid'), ('F2', 'dee');
INSERT INTO flights VALUES ('F6', 'TOS', NULL, 90, 1);
-- flights with city names
SELECT fno, a.city, b.city FROM flights JOIN airports a ON a.code = src JOIN airports b ON b.code = dst ORDER BY fno;
-- domestic flights
SELECT fno FROM flights f JOIN airports s ON s.code = f.src JOIN airports d ON d.code = f.dst
  WHERE s.country = d.country ORDER BY fno;
-- one-stop connections from Oslo
SELECT f1.fno, f2.fno, f1.mins + f2.mins AS total FROM flights f1 JOIN flights f2 ON f2.src = f1.dst
  WHERE f1.src = 'OSL' AND f2.dst <> 'OSL' ORDER BY total;
-- airports with no departures
SELECT code FROM airports WHERE code NOT IN (SELECT src FROM flights) ORDER BY code;
-- overbooked flights
SELECT fno, seats, (SELECT count(*) FROM bookings b WHERE b.fno = f.fno) AS booked FROM flights f
  WHERE seats < (SELECT count(*) FROM bookings b WHERE b.fno = f.fno) ORDER BY fno;
-- passengers and their trips
SELECT pax, count(*), sum(mins) FROM bookings JOIN flights USING (fno) GROUP BY pax ORDER BY pax;
-- departures per country, zero included
SELECT country, count(fno) FROM airports LEFT JOIN flights ON src = code GROUP BY country ORDER BY country;
-- free seats
SELECT fno, seats - count(pax) AS free FROM flights LEFT JOIN bookings USING (fno) GROUP BY fno ORDER BY free, fno;
UPDATE flights SET seats = seats + 1 WHERE fno IN (SELECT fno FROM bookings GROUP BY fno HAVING count(*) > 1);
SELECT fno, seats FROM flights ORDER BY fno;
SELECT fno FROM flights JOIN bookings USING (fno) WHERE pax = 'dee';
SELECT fno FROM flights JOIN bookings ON flights.fno = bookings.fno WHERE pax = 'dee';
SELECT city FROM airports a WHERE EXISTS (SELECT 1 FROM flights WHERE dst = a.code AND mins > 60) ORDER BY city;
