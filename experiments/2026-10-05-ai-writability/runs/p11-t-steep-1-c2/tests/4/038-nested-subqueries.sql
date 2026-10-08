-- Subqueries nested three deep, each referring outward.
CREATE TABLE region (rid INTEGER, rname TEXT);
CREATE TABLE store (sid INTEGER, rid INTEGER);
CREATE TABLE sale (sid INTEGER, amount INTEGER);
INSERT INTO region VALUES (1, 'north'), (2, 'south'), (3, 'east');
INSERT INTO store VALUES (10, 1), (11, 1), (20, 2), (30, 3);
INSERT INTO sale VALUES (10, 5), (10, 7), (11, 1), (20, 40), (30, 0);
SELECT rname FROM region r WHERE EXISTS
  (SELECT 1 FROM store s WHERE s.rid = r.rid AND EXISTS
    (SELECT 1 FROM sale WHERE sale.sid = s.sid AND amount > 6)) ORDER BY rname;
SELECT rname, (SELECT sum(amount) FROM sale WHERE sid IN
  (SELECT sid FROM store WHERE store.rid = region.rid)) FROM region ORDER BY rid;
SELECT rname FROM region WHERE rid IN (SELECT rid FROM store WHERE sid IN
  (SELECT sid FROM sale WHERE amount = (SELECT max(amount) FROM sale)));
