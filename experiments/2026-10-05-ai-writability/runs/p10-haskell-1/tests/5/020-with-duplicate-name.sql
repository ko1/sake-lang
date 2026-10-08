-- two ctes of one name are an error
WITH a AS (SELECT 1 AS x), a AS (SELECT 2 AS x) SELECT x FROM a;
WITH a AS (SELECT 1 AS x), b AS (SELECT 2 AS y), A AS (SELECT 3 AS z) SELECT y FROM b;
WITH a AS (SELECT 1 AS x), b AS (SELECT 2 AS x) SELECT x FROM a UNION SELECT x FROM b ORDER BY 1;
