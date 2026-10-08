CREATE TABLE prefs (user TEXT, theme TEXT UNIQUE DEFAULT 'light', size INTEGER DEFAULT '12');
INSERT INTO prefs (user) VALUES ('u1');
INSERT INTO prefs (user) VALUES ('u2');
INSERT INTO prefs (user, theme) VALUES ('u2', 'dark');
INSERT INTO prefs (user, theme) VALUES ('u3', NULL), ('u4', NULL);
SELECT user, coalesce(theme, '-'), size FROM prefs ORDER BY user;
