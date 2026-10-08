SELECT -(3), -(-(3)), - - - 3;
SELECT -'12', -' 4.5 ', -'x9', -'-8';
SELECT typeof(-'12'), typeof(-'4.5'), typeof(-'x');
SELECT +'  padded', +3.5, +-'2';
SELECT typeof(+'1'), typeof(+1), typeof(+NULL);
SELECT -1.0, -0, typeof(-0);
CREATE TABLE u (s TEXT, n INTEGER);
INSERT INTO u VALUES ('5', -5), ('-2.5', 2), ('abc', NULL);
SELECT s, -s, +s, -n FROM u ORDER BY s;
