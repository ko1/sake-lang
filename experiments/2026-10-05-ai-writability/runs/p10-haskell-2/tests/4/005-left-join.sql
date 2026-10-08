CREATE TABLE owners (id INTEGER, name TEXT);
CREATE TABLE pets (owner_id INTEGER, pet TEXT);
INSERT INTO owners VALUES (1, 'Ann'), (2, 'Bob'), (3, 'Cid');
INSERT INTO pets VALUES (1, 'cat'), (3, 'dog'), (4, 'fish');
SELECT name, pet FROM owners LEFT JOIN pets ON pets.owner_id = owners.id ORDER BY name;
SELECT name, owner_id, typeof(pet) FROM owners LEFT OUTER JOIN pets ON owner_id = id ORDER BY id;
SELECT pet, name FROM pets LEFT JOIN owners ON owners.id = pets.owner_id ORDER BY pet;
