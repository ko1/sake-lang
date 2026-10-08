-- Warehouses, stock levels and shipments.
CREATE TABLE wh (wid INTEGER PRIMARY KEY, site TEXT UNIQUE);
CREATE TABLE parts (pno TEXT PRIMARY KEY, descr TEXT, unit REAL);
CREATE TABLE stock (wid INTEGER NOT NULL, pno TEXT NOT NULL, qty INTEGER DEFAULT 0, UNIQUE (wid, pno));
CREATE TABLE moves (id INTEGER PRIMARY KEY, pno TEXT, from_wid INTEGER, to_wid INTEGER, qty INTEGER);
INSERT INTO wh (site) VALUES ('north'), ('south'), ('west');
INSERT INTO parts VALUES ('P1', 'bolt', 0.25), ('P2', 'nut', 0.1), ('P3', 'gear', 7.5), ('P4', 'cog', 2.0);
INSERT INTO stock VALUES (1, 'P1', 500), (1, 'P2', 900), (2, 'P1', 40), (2, 'P3', 12), (3, 'P3', 3);
INSERT INTO stock (wid, pno) VALUES (3, 'P2');
INSERT INTO moves (pno, from_wid, to_wid, qty) VALUES ('P1', 1, 2, 100), ('P3', 2, 3, 5), ('P2', 1, 3, 50);
-- stock value per site
SELECT site, sum(qty * unit) FROM wh JOIN stock USING (wid) JOIN parts USING (pno) GROUP BY site ORDER BY site;
-- parts held nowhere
SELECT pno, descr FROM parts WHERE NOT EXISTS (SELECT 1 FROM stock WHERE stock.pno = parts.pno AND qty > 0);
-- for each part, the site holding most of it
SELECT pno, (SELECT site FROM stock JOIN wh USING (wid) WHERE stock.pno = parts.pno ORDER BY qty DESC LIMIT 1)
  FROM parts ORDER BY pno;
-- moves with both site names
SELECT m.id, m.pno, f.site, t.site, m.qty FROM moves m JOIN wh f ON f.wid = m.from_wid
  JOIN wh t ON t.wid = m.to_wid ORDER BY m.id;
-- apply the moves to the stock
UPDATE stock SET qty = qty - (SELECT sum(qty) FROM moves WHERE moves.pno = stock.pno AND from_wid = stock.wid)
  WHERE EXISTS (SELECT 1 FROM moves WHERE moves.pno = stock.pno AND from_wid = stock.wid);
UPDATE stock SET qty = qty + (SELECT sum(qty) FROM moves WHERE moves.pno = stock.pno AND to_wid = stock.wid)
  WHERE EXISTS (SELECT 1 FROM moves WHERE moves.pno = stock.pno AND to_wid = stock.wid);
SELECT site, pno, qty FROM stock JOIN wh USING (wid) ORDER BY site, pno;
-- part counts per site, all sites and parts
SELECT site, descr, coalesce((SELECT qty FROM stock s WHERE s.wid = wh.wid AND s.pno = parts.pno), 0)
  FROM wh, parts WHERE unit > 1 ORDER BY site, descr;
-- sites with less than the average quantity of gears
SELECT site FROM wh JOIN stock USING (wid) WHERE pno = 'P3' AND qty < (SELECT avg(qty) FROM stock WHERE pno = 'P3');
INSERT INTO stock VALUES (2, 'P1', 1);
SELECT qty FROM stock JOIN moves USING (pno);
SELECT site FROM wh WHERE wid IN (SELECT to_wid FROM moves WHERE qty >= 50) ORDER BY site;
