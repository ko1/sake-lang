CREATE TABLE ws (w TEXT, n INTEGER);
INSERT INTO ws VALUES ('alpha', -3), ('beta', -4), ('gamma', 2);
SELECT abs(sum(n)), round(avg(n), 1), length(group_concat(w, '')) FROM ws;
SELECT upper(min(w)), lower(max(w)), coalesce(max(n), 0), nullif(count(*), 3) FROM ws;
SELECT substr(group_concat(w, '' ORDER BY w), 3, 4), instr(group_concat(w, ' ' ORDER BY w), 'gam') FROM ws;
SELECT replace(group_concat(w, ',' ORDER BY n), 'a', '') FROM ws;
SELECT typeof(abs(sum(n))), max(abs(n)), min(max(n), 0) FROM ws;
