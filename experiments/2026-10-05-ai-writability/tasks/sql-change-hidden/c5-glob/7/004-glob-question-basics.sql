SELECT 'dog' GLOB '???', 'dog' GLOB '??', 'dog' GLOB '????', 'dog' GLOB 'd?g', 'dg' GLOB 'd?g';
SELECT '' GLOB '?', 'x' GLOB '?', 'xy' GLOB '?*', 'x' GLOB '?*', '' GLOB '?*';
SELECT 'a.c' GLOB 'a?c', 'a?c' GLOB 'a?c', 'ABC' GLOB 'a?c', 'abc' LIKE 'a?c';
