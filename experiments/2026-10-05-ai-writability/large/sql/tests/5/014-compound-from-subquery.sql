-- a compound select as a FROM source, joined and aggregated
CREATE TABLE sales2023 (region TEXT, amount INTEGER);
CREATE TABLE sales2024 (region TEXT, amount INTEGER);
CREATE TABLE regions (code TEXT, label TEXT);
INSERT INTO sales2023 VALUES ('n', 10), ('s', 20), ('n', 5);
INSERT INTO sales2024 VALUES ('s', 7), ('e', 30), ('n', 1);
INSERT INTO regions VALUES ('n', 'North'), ('s', 'South'), ('e', 'East');
SELECT r.label, sum(x.amount) FROM (SELECT region, amount FROM sales2023 UNION ALL SELECT region, amount FROM sales2024) AS x JOIN regions r ON r.code = x.region GROUP BY r.label ORDER BY r.label;
SELECT count(*) FROM (SELECT region FROM sales2023 UNION SELECT region FROM sales2024);
SELECT region, total FROM (SELECT region, sum(amount) AS total FROM sales2023 GROUP BY region UNION ALL SELECT region, sum(amount) FROM sales2024 GROUP BY region) ORDER BY region, total;
