-- recursive ctes that build and take apart strings
WITH RECURSIVE s(i, acc) AS (SELECT 1, 'x' UNION ALL SELECT i + 1, acc || i FROM s WHERE i < 5) SELECT acc FROM s ORDER BY i DESC LIMIT 1;
WITH RECURSIVE ch(pos, c) AS (SELECT 1, substr('hello', 1, 1) UNION ALL SELECT pos + 1, substr('hello', pos + 1, 1) FROM ch WHERE pos < length('hello')) SELECT group_concat(c, '.') FROM ch;
WITH RECURSIVE rev(rest, out) AS (SELECT 'abcde', '' UNION ALL SELECT substr(rest, 2), substr(rest, 1, 1) || out FROM rev WHERE rest <> '') SELECT out FROM rev WHERE rest = '';
WITH RECURSIVE split(word, rest) AS (SELECT '', 'red,green,blue,' UNION ALL SELECT substr(rest, 1, instr(rest, ',') - 1), substr(rest, instr(rest, ',') + 1) FROM split WHERE rest <> '') SELECT word FROM split WHERE word <> '' ORDER BY word;
