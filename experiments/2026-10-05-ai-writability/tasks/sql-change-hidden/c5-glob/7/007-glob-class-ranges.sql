SELECT 'k' GLOB '[h-m]', 'h' GLOB '[h-m]', 'm' GLOB '[h-m]', 'n' GLOB '[h-m]', 'K' GLOB '[h-m]';
SELECT '7' GLOB '[0-6]', '3' GLOB '[0-6]', 'Q' GLOB '[A-Za-z]', '9' GLOB '[A-Za-z]';
SELECT 'b' GLOB '[c-a]', 'x' GLOB '[x-x]', 'xy' GLOB 'x[y', 'x[y' GLOB 'x[y', 'abc' GLOB '*[c';
CREATE TABLE parts (sku TEXT);
INSERT INTO parts VALUES ('K100'), ('K2'), ('M310'), ('k100'), ('Z99'), ('K10A');
SELECT sku FROM parts WHERE sku GLOB '[J-M][0-9][0-9]*' ORDER BY sku;
SELECT sku FROM parts WHERE sku GLOB '*[0-9]' ORDER BY sku;
SELECT sku FROM parts WHERE sku GLOB '[A-Z]*[A-Z]' ORDER BY sku;
