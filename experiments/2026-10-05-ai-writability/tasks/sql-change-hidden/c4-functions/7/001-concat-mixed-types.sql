-- concat: text forms of INTEGER, REAL and TEXT arguments
SELECT concat(0.1 + 0.2, '/', 2.0 / 4);
SELECT concat(-0.0, 100.0), concat(1.5e-7);
SELECT concat('it''s', ' ', 'ok');
SELECT length(concat(123, 4.5)), upper(concat('ab', 'cd'));
SELECT concat(typeof(1), typeof(NULL));
