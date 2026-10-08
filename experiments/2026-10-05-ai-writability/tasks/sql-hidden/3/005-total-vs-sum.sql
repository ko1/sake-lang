CREATE TABLE donations (donor TEXT, amount INTEGER);
INSERT INTO donations VALUES ('a', 10), ('b', NULL), ('a', 15), ('c', NULL);
SELECT donor, sum(amount), total(amount), typeof(total(amount)) FROM donations GROUP BY donor ORDER BY donor;
SELECT total(amount) + 1, sum(amount) + 1 FROM donations WHERE donor = 'c';
SELECT total(DISTINCT amount), total(amount * 0.5) FROM donations;
SELECT total(donor) FROM donations;
