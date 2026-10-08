-- USING (c1, c2) requires both columns to be equal.
CREATE TABLE plan (yr INTEGER, qtr INTEGER, target INTEGER);
CREATE TABLE actual (yr INTEGER, qtr INTEGER, amount INTEGER);
INSERT INTO plan VALUES (2024, 1, 100), (2024, 2, 120), (2025, 1, 130);
INSERT INTO actual VALUES (2024, 1, 90), (2024, 2, 150), (2025, 2, 40), (2023, 1, 70);
SELECT yr, qtr, target, amount FROM plan JOIN actual USING (yr, qtr) ORDER BY yr, qtr;
SELECT yr, qtr, target, amount FROM plan LEFT JOIN actual USING (qtr, yr) ORDER BY yr, qtr;
SELECT count(*) FROM plan JOIN actual USING (qtr);
