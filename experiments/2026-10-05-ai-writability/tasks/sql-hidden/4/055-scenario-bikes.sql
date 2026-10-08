-- A bike rental: stations, bikes, rides.
CREATE TABLE stations (st INTEGER PRIMARY KEY, sname TEXT UNIQUE);
CREATE TABLE bikes (bike INTEGER PRIMARY KEY, model TEXT, home INTEGER);
CREATE TABLE rides (rid INTEGER PRIMARY KEY, bike INTEGER, src INTEGER, dst INTEGER, mins INTEGER);
INSERT INTO stations VALUES (1, 'Dock'), (2, 'Mall'), (3, 'Park');
INSERT INTO bikes VALUES (7, 'city', 1), (8, 'city', 2), (9, 'ebike', 3), (10, 'ebike', NULL);
INSERT INTO rides (bike, src, dst, mins) VALUES (7, 1, 2, 12), (7, 2, 3, 8), (8, 2, 2, 30), (9, 3, 1, 15), (7, 3, 1, 9);
INSERT INTO stations (sname) VALUES ('Mall');
-- rides with station names
SELECT rid, s.sname, d.sname, mins FROM rides JOIN stations s ON s.st = src JOIN stations d ON d.st = dst ORDER BY rid;
-- minutes per model, models with idle bikes included
SELECT model, count(rid), total(mins) FROM bikes LEFT JOIN rides USING (bike) GROUP BY model ORDER BY model;
-- round trips
SELECT rid FROM rides WHERE src = dst;
-- arrivals minus departures per station
SELECT sname, (SELECT count(*) FROM rides WHERE dst = st) - (SELECT count(*) FROM rides WHERE src = st) AS net
  FROM stations ORDER BY net, sname;
-- bikes that ended away from home after their last ride
SELECT b.bike FROM bikes b JOIN rides r ON r.bike = b.bike WHERE r.rid = (SELECT max(rid) FROM rides WHERE bike = b.bike)
  AND r.dst <> b.home ORDER BY b.bike;
-- bikes never ridden
SELECT bike, model FROM bikes WHERE NOT EXISTS (SELECT 1 FROM rides WHERE rides.bike = bikes.bike);
-- longest ride per bike that rode
SELECT bike, max(mins) FROM rides GROUP BY bike HAVING count(*) >= 1 ORDER BY bike;
UPDATE bikes SET home = (SELECT st FROM stations WHERE sname = 'Park') WHERE home IS NULL;
SELECT bike, sname FROM bikes JOIN stations ON st = home ORDER BY bike;
SELECT bike FROM bikes JOIN rides ON rides.bike = bikes.bike WHERE mins > 20;
SELECT model FROM bikes JOIN rides USING (bike) WHERE src IN (SELECT st FROM stations WHERE sname = 'Mall') ORDER BY rid;
SELECT sname FROM stations WHERE st IN (SELECT src, dst FROM rides);
SELECT s.sname, count(r.rid) FROM stations s LEFT JOIN rides r ON r.src = s.st AND r.mins < 10 GROUP BY s.st ORDER BY s.st;
