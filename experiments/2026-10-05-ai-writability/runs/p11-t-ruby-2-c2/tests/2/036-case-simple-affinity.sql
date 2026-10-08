-- CASE x WHEN v compares like x = v, with affinity
CREATE TABLE f (s TEXT, i INTEGER);
INSERT INTO f VALUES ('12', 12), ('3.0', 3);
SELECT s, CASE s WHEN 12 THEN 'twelve' WHEN 3 THEN 'three' WHEN 3.0 THEN 'three-point-oh' ELSE 'other' END FROM f ORDER BY i;
SELECT i, CASE i WHEN '12' THEN 'text twelve' WHEN ' 3 ' THEN 'padded three' ELSE 'no' END FROM f ORDER BY i;
SELECT CASE 12 WHEN '12' THEN 'converted' ELSE 'not converted' END;
