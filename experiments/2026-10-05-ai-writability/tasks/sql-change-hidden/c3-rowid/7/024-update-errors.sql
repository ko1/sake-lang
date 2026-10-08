-- an UPDATE of the rowid to NULL, a non-integer or a taken value changes nothing
CREATE TABLE gr (g TEXT);
INSERT INTO gr VALUES ('p'), ('q'), ('r');
UPDATE gr SET rowid = '2.5' WHERE g = 'p';
UPDATE gr SET _rowid_ = NULL;
UPDATE gr SET rowid = 3 WHERE g = 'q';
UPDATE gr SET rowid = '30' WHERE g = 'q';
SELECT rowid, g FROM gr ORDER BY 1;
