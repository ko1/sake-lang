-- INSERT ... SELECT fills unlisted columns with defaults and INTEGER PRIMARY KEY values
CREATE TABLE src (name TEXT, pts INTEGER);
CREATE TABLE board (rank INTEGER PRIMARY KEY, name TEXT NOT NULL, pts INTEGER DEFAULT -1, tag TEXT DEFAULT 'new');
INSERT INTO src VALUES ('zed', 7), ('amy', 9), ('kim', 4);
INSERT INTO board (name, pts) SELECT name, pts FROM src ORDER BY pts DESC;
INSERT INTO board (name) SELECT 'late';
INSERT INTO board (rank, name) SELECT 10, 'ten';
INSERT INTO board (name, tag) SELECT name, NULL FROM src WHERE pts < 5;
SELECT rank, name, pts, tag FROM board ORDER BY rank;
INSERT INTO board (rank, name) SELECT rank, 'dup' FROM board WHERE rank = 2;
INSERT INTO board (name) SELECT NULL;
SELECT count(*) FROM board;
