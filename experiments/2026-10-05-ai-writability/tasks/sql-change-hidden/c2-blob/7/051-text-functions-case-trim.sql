SELECT upper(X'6869'), lower(X'4849'), typeof(upper(X'6869'));
SELECT trim(X'2020782020'), ltrim(X'2078'), rtrim(X'7820'), trim(X'2D2D782D', '-');
SELECT replace(X'612D62', '-', '+'), replace('a.b', X'2E', X'2F'), typeof(replace(X'61', 'a', 'b'));
