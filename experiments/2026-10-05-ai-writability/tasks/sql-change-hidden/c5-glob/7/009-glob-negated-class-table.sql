CREATE TABLE ids (code TEXT);
INSERT INTO ids VALUES ('A12'), ('B7'), ('9X'), ('_tmp'), ('a1'), ('C');
SELECT code FROM ids WHERE code GLOB '[^0-9]*' ORDER BY code;
SELECT code FROM ids WHERE code GLOB '[^A-Z]*' ORDER BY code;
SELECT code FROM ids WHERE code GLOB '*[^0-9]' ORDER BY code;
SELECT count(*) FROM ids WHERE code GLOB '[^_]?*';
