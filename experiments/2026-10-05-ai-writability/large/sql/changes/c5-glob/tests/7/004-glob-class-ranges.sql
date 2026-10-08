SELECT 'm' GLOB '[a-z]', 'M' GLOB '[a-z]', 'M' GLOB '[A-Z]', '5' GLOB '[0-9]', '55' GLOB '[0-9]';
SELECT 'b12' GLOB '[a-c][0-9]*', 'd12' GLOB '[a-c][0-9]*', 'b' GLOB '[a-c][0-9]*';
SELECT 'q' GLOB '[a-cx-z]', 'y' GLOB '[a-cx-z]', 'B' GLOB '[a-zA-Z]', '_' GLOB '[a-zA-Z]';
-- a reversed range contains nothing; an unclosed [ matches nothing
SELECT 'c' GLOB '[z-a]', 'a' GLOB '[z-a]', 'a' GLOB '[a', '[' GLOB '[', 'ab' GLOB 'a[b';
CREATE TABLE plates (plate TEXT);
INSERT INTO plates VALUES ('AB-123'), ('ab-123'), ('XY-9'), ('CD-45'), ('C1-234');
SELECT plate FROM plates WHERE plate GLOB '[A-Z][A-Z]-[0-9]*' ORDER BY plate;
SELECT plate FROM plates WHERE plate GLOB '*-[0-9][0-9][0-9]' ORDER BY plate;
SELECT plate FROM plates WHERE plate GLOB '[A-Z][0-9A-Z]-*' ORDER BY plate DESC;
