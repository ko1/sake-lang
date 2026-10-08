CREATE TABLE shifts (worker TEXT, day INTEGER, slot TEXT);
CREATE TABLE needs (day INTEGER, slot TEXT, task TEXT);
INSERT INTO shifts VALUES ('kim', 1, 'am'), ('kim', 2, 'pm'), ('lou', 1, 'pm'), ('max', 2, 'am');
INSERT INTO needs VALUES (1, 'am', 'open'), (1, 'pm', 'close'), (2, 'am', 'stock'), (3, 'am', 'clean');
SELECT worker, task FROM shifts JOIN needs ON shifts.day = needs.day AND shifts.slot = needs.slot ORDER BY worker, task;
SELECT worker, task FROM shifts s INNER JOIN needs n ON s.day = n.day OR n.task = 'clean' ORDER BY worker, task;
SELECT task FROM needs n JOIN shifts s ON n.day = s.day AND n.slot = s.slot AND s.worker LIKE 'k%' ORDER BY task;
SELECT count(*) FROM shifts JOIN needs ON needs.day > shifts.day;
