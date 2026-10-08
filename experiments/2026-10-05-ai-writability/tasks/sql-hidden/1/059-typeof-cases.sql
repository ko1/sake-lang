SELECT typeof(0), typeof(0.0), typeof(''), typeof(NULL);
SELECT typeof(1 + 2.0), typeof(5 / 2), typeof(5 % 2.0), typeof('5' * '2');
SELECT typeof(-'x'), typeof(+'x'), typeof(1 = 1), typeof(1 IS NULL);
SELECT typeof(upper(1)), typeof(length(1)), typeof(abs('1')), typeof(coalesce(NULL, 1.0));
SELECT typeof(nullif(1, 1)), typeof(nullif(1, 2)), typeof(ifnull(NULL, 'z'));
SELECT TypeOf(typeof(1)), typeof(NULL AND 1), typeof(0 AND NULL);
CREATE TABLE ty (i INTEGER, r REAL, t TEXT);
INSERT INTO ty VALUES ('5', '5', 5), (5.0, 5.0, 5.0), (NULL, NULL, NULL);
SELECT typeof(i), typeof(r), typeof(t), t FROM ty ORDER BY t NULLS LAST;
