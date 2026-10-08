CREATE TABLE ws (w TEXT);
INSERT INTO ws VALUES ('Tea'), ('tea'), ('coffee'), ('TEA'), ('Cocoa'), ('cocoa');
SELECT DISTINCT lower(w) AS lw FROM ws ORDER BY lw;
SELECT DISTINCT length(w) FROM ws ORDER BY 1 DESC;
SELECT DISTINCT substr(lower(w), 1, 2) AS pre, length(w) FROM ws ORDER BY pre, 2;
SELECT DISTINCT w LIKE 'tea' FROM ws ORDER BY 1;
