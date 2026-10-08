CREATE TABLE codes (code TEXT PRIMARY KEY, label TEXT);
INSERT INTO codes VALUES ('US', 'United States'), ('FR', 'France');
INSERT INTO codes VALUES ('FR', 'Francia');
INSERT INTO codes VALUES (NULL, 'Nowhere');
INSERT INTO codes (label) VALUES ('Nowhere');
INSERT INTO codes VALUES ('fr', 'lowercase');
SELECT code, label FROM codes ORDER BY code;
