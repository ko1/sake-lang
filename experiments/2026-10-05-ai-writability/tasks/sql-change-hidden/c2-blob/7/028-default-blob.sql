CREATE TABLE cfg (name TEXT, val BLOB DEFAULT X'CAFE', flag BLOB DEFAULT NULL);
INSERT INTO cfg (name) VALUES ('a');
INSERT INTO cfg (name, val) VALUES ('b', X'01');
INSERT INTO cfg (name, flag) VALUES ('c', X'');
SELECT name, val, flag FROM cfg ORDER BY name;
