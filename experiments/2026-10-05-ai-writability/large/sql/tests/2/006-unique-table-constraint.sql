CREATE TABLE seats (row_no INTEGER, seat INTEGER, guest TEXT, UNIQUE (row_no, seat));
INSERT INTO seats VALUES (1, 1, 'amy'), (1, 2, 'ben'), (2, 1, 'cal');
INSERT INTO seats VALUES (2, 2, 'dan');
INSERT INTO seats VALUES (1, 2, 'eve');
INSERT INTO seats VALUES (1, NULL, 'fay'), (1, NULL, 'gus');
SELECT row_no, seat, guest FROM seats ORDER BY row_no, seat NULLS LAST, guest;
UPDATE seats SET seat = 1 WHERE guest = 'dan';
