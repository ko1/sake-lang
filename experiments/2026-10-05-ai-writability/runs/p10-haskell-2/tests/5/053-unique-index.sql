-- a UNIQUE index is a uniqueness constraint on its columns
CREATE TABLE login (user TEXT, site TEXT, pw TEXT);
CREATE UNIQUE INDEX login_us ON login (user, site);
INSERT INTO login VALUES ('ann', 'mail', 'x'), ('ann', 'bank', 'y'), ('bob', 'mail', 'z');
INSERT INTO login VALUES ('ann', 'mail', 'w');
INSERT INTO login VALUES ('cy', 'web', '1'), ('cy', 'web', '2');
INSERT INTO login VALUES ('dan', NULL, '1'), ('dan', NULL, '2');
UPDATE login SET site = 'mail' WHERE user = 'ann' AND site = 'bank';
UPDATE login SET user = 'BOB' WHERE user = 'bob';
SELECT user, site, pw FROM login ORDER BY user, pw;
