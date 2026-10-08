-- A hotel: rooms, guests and stays.
CREATE TABLE rooms (rno INTEGER PRIMARY KEY, kind TEXT NOT NULL, rate INTEGER);
CREATE TABLE guests (gid INTEGER PRIMARY KEY, gname TEXT UNIQUE, vip INTEGER DEFAULT 0);
CREATE TABLE stays (rno INTEGER, gid INTEGER, night_in INTEGER, night_out INTEGER, UNIQUE (rno, night_in));
INSERT INTO rooms VALUES (101, 'single', 80), (102, 'double', 120), (201, 'suite', 300), (202, 'double', 130);
INSERT INTO guests (gname, vip) VALUES ('Ola', 1), ('Kari', 0), ('Nils', 0);
INSERT INTO guests (gname) VALUES ('Siri');
INSERT INTO stays VALUES (101, 2, 1, 3), (102, 1, 1, 5), (201, 1, 6, 8), (101, 3, 3, 4), (202, 4, 2, 3);
INSERT INTO stays VALUES (102, 3, 1, 2);
-- bill per stay
SELECT gname, rno, kind, (night_out - night_in) * rate AS bill FROM stays JOIN rooms USING (rno)
  JOIN guests USING (gid) ORDER BY gname, rno;
-- revenue per room kind, unused kinds as 0
SELECT kind, coalesce(sum((night_out - night_in) * rate), 0) FROM rooms LEFT JOIN stays USING (rno)
  GROUP BY kind ORDER BY kind;
-- rooms free on night 3 (occupied when night_in <= 3 < night_out)
SELECT rno FROM rooms r WHERE NOT EXISTS (SELECT 1 FROM stays s WHERE s.rno = r.rno AND night_in <= 3 AND 3 < night_out)
  ORDER BY rno;
-- the guest who spent most
SELECT gname, (SELECT sum((night_out - night_in) * rate) FROM stays JOIN rooms USING (rno) WHERE stays.gid = guests.gid)
  AS spent FROM guests ORDER BY spent DESC LIMIT 2;
-- guests who never stayed in a double
SELECT gname FROM guests WHERE gid NOT IN (SELECT gid FROM stays JOIN rooms USING (rno) WHERE kind = 'double')
  ORDER BY gname;
-- VIP discount on future stays
UPDATE rooms SET rate = rate - 10 WHERE rno IN (SELECT rno FROM stays WHERE gid IN (SELECT gid FROM guests WHERE vip = 1));
SELECT rno, rate FROM rooms ORDER BY rno;
SELECT gname, count(rno) AS n FROM guests LEFT JOIN stays USING (gid) GROUP BY gname ORDER BY n DESC, gname;
SELECT rno FROM rooms JOIN stays ON rooms.rno = stays.rno WHERE gid = 1;
SELECT g.gname FROM guests g WHERE guests.vip = 1;
SELECT gname FROM guests WHERE gid = (SELECT gid FROM stays WHERE rno = 201);
SELECT kind, count(*) FROM rooms WHERE rno IN (SELECT rno FROM stays) GROUP BY kind ORDER BY kind;
DELETE FROM stays WHERE gid = (SELECT gid FROM guests WHERE gname = 'Siri');
SELECT count(*) FROM stays;
