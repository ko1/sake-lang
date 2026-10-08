-- A small lending library.
CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT NOT NULL, author TEXT);
CREATE TABLE members (id INTEGER PRIMARY KEY, name TEXT UNIQUE);
CREATE TABLE loans (book_id INTEGER, member_id INTEGER, out_day INTEGER, back_day INTEGER);
INSERT INTO books (title, author) VALUES ('Dune', 'Herbert'), ('Emma', 'Austen'), ('Ulysses', 'Joyce');
INSERT INTO books (title, author) VALUES ('Persuasion', 'Austen'), ('Kim', 'Kipling');
INSERT INTO members (name) VALUES ('ann'), ('bob'), ('cid');
INSERT INTO loans VALUES (1, 1, 1, 5), (2, 1, 3, NULL), (1, 2, 6, NULL), (4, 3, 2, 4), (3, 2, 7, 9);
-- books currently out, with who has them
SELECT title, name FROM loans JOIN books ON books.id = book_id JOIN members ON members.id = member_id
  WHERE back_day IS NULL ORDER BY title;
-- every book with its number of loans
SELECT title, count(book_id) FROM books LEFT JOIN loans ON book_id = books.id GROUP BY books.id ORDER BY title;
-- books never lent
SELECT title FROM books WHERE id NOT IN (SELECT book_id FROM loans) ORDER BY title;
SELECT title FROM books b WHERE NOT EXISTS (SELECT 1 FROM loans WHERE book_id = b.id) ORDER BY title;
-- members and their open loans (zero included)
SELECT name, count(out_day) FROM members m LEFT JOIN loans l ON l.member_id = m.id AND l.back_day IS NULL
  GROUP BY m.id ORDER BY name;
-- authors read by ann
SELECT DISTINCT author FROM books JOIN loans ON book_id = books.id
  WHERE member_id = (SELECT id FROM members WHERE name = 'ann') ORDER BY author;
-- returning a book
UPDATE loans SET back_day = 8 WHERE back_day IS NULL AND book_id = (SELECT id FROM books WHERE title = 'Dune');
SELECT title, out_day, back_day FROM books JOIN loans ON book_id = books.id WHERE title = 'Dune' ORDER BY out_day;
-- longest loan per book among returned ones
SELECT title, max(back_day - out_day) FROM books JOIN loans ON book_id = books.id
  WHERE back_day IS NOT NULL GROUP BY title ORDER BY title;
INSERT INTO members (name) VALUES ((SELECT name FROM members WHERE id = 2));
SELECT name, (SELECT group_concat(title, ', ' ORDER BY title) FROM books JOIN loans ON book_id = books.id
  WHERE member_id = members.id) FROM members ORDER BY name;
SELECT members.title FROM members;
SELECT title FROM books JOIN members ON id = 1;
DELETE FROM loans WHERE member_id IN (SELECT id FROM members WHERE name = 'cid');
SELECT count(*), count(DISTINCT member_id) FROM loans;
