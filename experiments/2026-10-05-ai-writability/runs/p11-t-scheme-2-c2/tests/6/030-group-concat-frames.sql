-- group_concat over a frame adds the rows in partition order
CREATE TABLE word (pos INTEGER, line INTEGER, w TEXT);
INSERT INTO word VALUES (1,1,'the'),(2,1,'cat'),(3,1,'sat'),(1,2,'on'),(2,2,'a'),(3,2,'mat'),(4,2,NULL);
SELECT line, pos, group_concat(w, ' ') OVER (PARTITION BY line ORDER BY pos) FROM word ORDER BY line, pos;
SELECT line, pos, group_concat(w) OVER (PARTITION BY line ORDER BY pos DESC ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) FROM word ORDER BY line, pos;
SELECT line, pos, group_concat(w, '+') OVER (ORDER BY line, pos ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM word ORDER BY line, pos;
SELECT line, pos, group_concat(pos, '') OVER (PARTITION BY line ORDER BY pos ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) FROM word ORDER BY line, pos;
