CREATE TABLE words (w TEXT);
INSERT INTO words VALUES ('cot'), ('cut'), ('coat'), ('Cut'), ('ct'), ('cute');
SELECT w FROM words WHERE w GLOB 'c?t' ORDER BY w;
SELECT w FROM words WHERE w GLOB 'c??t' ORDER BY w;
SELECT w FROM words WHERE w GLOB '?ut*' ORDER BY w;
SELECT w, length(w) FROM words WHERE w GLOB '????' ORDER BY w;
