/* leading block */ SELECT /* a */ 1 /* b */ + /* c */ 2 /* d */;
SELECT 10 -- minus would start a comment only as two dashes
 - 3;
SELECT 4 - -2;
SELECT 'x' -- ; not the end
  || 'y';
/* block with -- inside */ SELECT 5;
-- line with /* not a block
SELECT 6;
CREATE TABLE t (a INTEGER /* the key */, b TEXT -- the label
);
INSERT INTO t VALUES (1, 'one') /* trailing */;
SELECT * FROM t;
