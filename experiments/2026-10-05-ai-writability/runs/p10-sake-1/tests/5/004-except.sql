-- EXCEPT keeps the distinct rows of the left side that are not on the right
CREATE TABLE stock (item TEXT);
CREATE TABLE sold (item TEXT);
INSERT INTO stock VALUES ('pen'), ('ink'), ('pen'), ('cap'), ('box');
INSERT INTO sold VALUES ('ink'), ('box'), ('lid');
SELECT item FROM stock EXCEPT SELECT item FROM sold ORDER BY item;
SELECT item FROM sold EXCEPT SELECT item FROM stock ORDER BY item;
SELECT 5 EXCEPT SELECT 5;
SELECT count(*) FROM (SELECT item FROM stock EXCEPT SELECT 'zzz');
