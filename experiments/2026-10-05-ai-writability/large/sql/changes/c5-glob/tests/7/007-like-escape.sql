SELECT 'a%b' LIKE 'a!%b' ESCAPE '!', 'axb' LIKE 'a!%b' ESCAPE '!', 'a%b' LIKE 'a%b' ESCAPE '!';
SELECT 'a_b' LIKE 'a!_b' ESCAPE '!', 'axb' LIKE 'a!_b' ESCAPE '!', 'axb' LIKE 'a_b' ESCAPE '!';
-- escaped and ordinary letters still ignore case
SELECT 'A%' LIKE 'a!%' ESCAPE '!', 'x' LIKE '!x' ESCAPE '!', 'X' LIKE '!x' ESCAPE '!';
CREATE TABLE discounts (id INTEGER PRIMARY KEY, label TEXT);
INSERT INTO discounts (label) VALUES ('10% off'), ('100 off'), ('save 5%'), ('half_price'), ('halfprice'), ('50%');
SELECT id, label FROM discounts WHERE label LIKE '%\%%' ESCAPE '\' ORDER BY id;
SELECT id FROM discounts WHERE label LIKE '%\%' ESCAPE '\' ORDER BY id;
SELECT id FROM discounts WHERE label LIKE 'half\_%' ESCAPE '\' ORDER BY id;
SELECT id FROM discounts WHERE label LIKE 'half_%' ORDER BY id;
SELECT id FROM discounts WHERE label NOT LIKE '%#%%' ESCAPE '#' ORDER BY id;
SELECT 'a' LIKE 'a' ESCAPE '!' = 1, 'a' LIKE 'b' ESCAPE '!' = 0;
