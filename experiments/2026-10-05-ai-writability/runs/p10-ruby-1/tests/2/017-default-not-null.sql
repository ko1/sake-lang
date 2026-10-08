CREATE TABLE acct (name TEXT NOT NULL, balance INTEGER NOT NULL DEFAULT 0, tier TEXT NOT NULL DEFAULT NULL);
INSERT INTO acct (name, tier) VALUES ('ana', 'gold');
INSERT INTO acct (name) VALUES ('bo');
INSERT INTO acct (name, balance, tier) VALUES ('cy', NULL, 'gold');
INSERT INTO acct (name, balance, tier) VALUES ('di', 25, 'silver');
SELECT name, balance, tier FROM acct ORDER BY name;
