-- several UNIQUE indexes; NULLs never conflict; UPDATE is checked too
CREATE TABLE car (plate TEXT, vin TEXT, owner TEXT, slot INTEGER);
CREATE UNIQUE INDEX car_plate ON car (plate);
CREATE UNIQUE INDEX car_owner_slot ON car (owner, slot);
INSERT INTO car VALUES ('AB1', 'v1', 'ann', 1), ('CD2', 'v2', 'ann', 2), (NULL, 'v3', 'bob', NULL), (NULL, 'v4', 'bob', NULL);
INSERT INTO car VALUES ('ab1', 'v5', 'cy', 1);
INSERT INTO car VALUES ('AB1', 'v6', 'dan', 1);
INSERT INTO car VALUES ('EF3', 'v7', 'ann', 2);
UPDATE car SET slot = 1 WHERE vin = 'v2';
UPDATE car SET plate = 'ZZ9' WHERE owner = 'bob';
UPDATE car SET plate = 'XY7', slot = 5 WHERE vin = 'v3';
SELECT plate, vin, owner, slot FROM car ORDER BY vin;
