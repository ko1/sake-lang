-- concat joins the text forms of its arguments
SELECT concat('foo', 'bar');
SELECT concat('x');
SELECT concat(1, 2, 3), typeof(concat(1, 2, 3));
SELECT concat('v', 2.5), concat(10, '.', 0.5);
SELECT concat(1e20, '|'), concat(-7, 3.0);
SELECT CONCAT('up', 'per'), Concat(upper('a'), lower('B'));
