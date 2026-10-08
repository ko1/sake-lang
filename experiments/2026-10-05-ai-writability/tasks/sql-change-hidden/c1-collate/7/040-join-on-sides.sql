-- ON comparisons choose the collation by operand order like any comparison.
CREATE TABLE cust (id INTEGER, name TEXT COLLATE NOCASE);
CREATE TABLE ord (oid INTEGER, name TEXT);
INSERT INTO cust VALUES (1, 'Ivy'), (2, 'jon');
INSERT INTO ord VALUES (10, 'IVY'), (11, 'Jon'), (12, 'jon'), (13, 'ivy');
SELECT id, oid FROM cust JOIN ord ON cust.name = ord.name ORDER BY oid;
SELECT id, oid FROM cust JOIN ord ON ord.name = cust.name ORDER BY oid;
SELECT id, oid FROM ord JOIN cust ON ord.name = cust.name COLLATE NOCASE ORDER BY oid;
SELECT oid, id FROM ord LEFT JOIN cust ON ord.name = cust.name ORDER BY oid;
