CREATE TABLE logs (id INTEGER PRIMARY KEY, line TEXT);
INSERT INTO logs (line) VALUES ('ERROR disk full'), ('error retry'), ('INFO started'), ('WARN slow'), ('ERROR timeout');
SELECT id FROM logs WHERE line NOT GLOB 'ERROR*' ORDER BY id;
SELECT id FROM logs WHERE line NOT GLOB '*[a-s]' ORDER BY id;
SELECT 'abc' NOT GLOB 'a*', 'abc' NOT GLOB 'b*', 'A' NOT GLOB 'a';
SELECT id FROM logs WHERE NOT line GLOB '[EW]*' ORDER BY id;
SELECT id, line NOT GLOB '*t*' FROM logs ORDER BY id;
SELECT count(*) FROM logs WHERE line GLOB 'ERROR*' AND line NOT GLOB '*full';
