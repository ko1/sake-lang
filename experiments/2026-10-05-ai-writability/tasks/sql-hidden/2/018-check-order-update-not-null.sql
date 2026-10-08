CREATE TABLE p (a TEXT NOT NULL, b INTEGER, c TEXT NOT NULL);
INSERT INTO p VALUES ('x', 1, 'y');
UPDATE p SET c = NULL, a = NULL;
UPDATE p SET c = NULL, b = 'z';
UPDATE p SET b = 'z', a = 'w';
UPDATE p SET b = '2', c = 'q';
SELECT a, b, c FROM p;
