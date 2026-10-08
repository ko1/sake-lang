-- An unknown collation name is an error, spelled as written; the statement has no effect.
CREATE TABLE a (x TEXT COLLATE UPPERCASE);
SELECT count(*) FROM a;
CREATE TABLE b (x TEXT COLLATE NOCASE);
INSERT INTO b VALUES ('Q');
SELECT x FROM b WHERE x = 'q' COLLATE Fold;
SELECT x FROM b WHERE 0 ORDER BY x COLLATE sortme;
SELECT x FROM b WHERE x COLLATE BINARY = 'q';
SELECT x FROM b WHERE x COLLATE Binary = 'Q';
