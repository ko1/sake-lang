-- the rowid of the NULL-extended side of a LEFT JOIN is NULL
CREATE TABLE cust (cn TEXT);
CREATE TABLE ord (cid INTEGER, total INTEGER);
INSERT INTO cust VALUES ('ada'), ('bo'), ('cat');
INSERT INTO ord VALUES (1, 50), (3, 20), (1, 5);
SELECT cn, ord.rowid, total FROM cust LEFT JOIN ord ON ord.cid = cust.rowid ORDER BY cn, ord.rowid;
SELECT cn FROM cust LEFT JOIN ord ON ord.cid = cust.rowid WHERE ord.rowid IS NULL;
SELECT cn, count(ord.oid) FROM cust LEFT JOIN ord ON cid = cust.oid GROUP BY cn ORDER BY cn;
