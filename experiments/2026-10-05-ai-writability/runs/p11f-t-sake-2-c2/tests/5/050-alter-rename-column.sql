-- RENAME COLUMN renames a column; constraints and indexes follow it
CREATE TABLE person (nm TEXT NOT NULL, mail TEXT UNIQUE, age INTEGER);
INSERT INTO person VALUES ('ann', 'a@x', 30);
ALTER TABLE person RENAME COLUMN nm TO name;
ALTER TABLE person RENAME mail TO email;
CREATE INDEX person_age ON person (age);
ALTER TABLE person RENAME COLUMN age TO years;
SELECT name, email, years FROM person;
SELECT nm FROM person;
INSERT INTO person VALUES (NULL, 'b@x', 1);
INSERT INTO person VALUES ('bob', 'a@x', 2);
INSERT INTO person (name, years) VALUES ('cy', 'old');
ALTER TABLE person RENAME COLUMN nm TO given;
ALTER TABLE person RENAME COLUMN Missing TO other;
SELECT * FROM person;
