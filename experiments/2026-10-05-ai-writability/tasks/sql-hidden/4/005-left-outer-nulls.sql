CREATE TABLE hosts (name TEXT, ip TEXT);
CREATE TABLE pings (ip TEXT, ms REAL, ok INTEGER);
INSERT INTO hosts VALUES ('db', '10.0.0.2'), ('web', '10.0.0.3'), ('mail', '10.0.0.9');
INSERT INTO pings VALUES ('10.0.0.3', 1.25, 1), ('10.0.0.2', 0.5, 0);
SELECT name, ms, ok, typeof(ms), typeof(ok) FROM hosts LEFT OUTER JOIN pings ON pings.ip = hosts.ip ORDER BY name;
SELECT name, coalesce(ms, -1.0), ifnull(ok, 'never') FROM hosts LEFT JOIN pings ON pings.ip = hosts.ip ORDER BY name;
SELECT name FROM hosts LEFT JOIN pings ON pings.ip = hosts.ip WHERE NOT ok ORDER BY name;
SELECT name, pings.ip IS NULL FROM hosts LEFT JOIN pings ON pings.ip = hosts.ip ORDER BY 2, 1;
