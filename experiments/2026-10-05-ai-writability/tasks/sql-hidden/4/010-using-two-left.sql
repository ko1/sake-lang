CREATE TABLE seats (row_no INTEGER, col_no INTEGER, price INTEGER);
CREATE TABLE sold (col_no INTEGER, row_no INTEGER, buyer TEXT);
INSERT INTO seats VALUES (1, 1, 50), (1, 2, 50), (2, 1, 30), (2, 2, 30);
INSERT INTO sold VALUES (2, 1, 'amy'), (1, 2, 'ben'), (3, 3, 'cy');
SELECT row_no, col_no, price, buyer FROM seats LEFT JOIN sold USING (row_no, col_no) ORDER BY row_no, col_no;
SELECT row_no, col_no FROM seats LEFT JOIN sold USING (row_no, col_no) WHERE buyer IS NULL ORDER BY 1, 2;
SELECT sum(price) FROM seats JOIN sold USING (col_no, row_no);
SELECT buyer, seats.row_no, sold.col_no FROM sold LEFT JOIN seats USING (row_no, col_no) ORDER BY buyer;
