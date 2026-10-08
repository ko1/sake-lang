-- INSERT ... SELECT with a column list; unlisted columns get their default
CREATE TABLE people (fname TEXT, lname TEXT);
CREATE TABLE contacts (id INTEGER PRIMARY KEY, fullname TEXT, kind TEXT DEFAULT 'person', note TEXT);
INSERT INTO people VALUES ('Ada', 'Lovelace'), ('Alan', 'Turing');
INSERT INTO contacts (fullname) SELECT fname || ' ' || lname FROM people ORDER BY lname;
INSERT INTO contacts (note, fullname) SELECT 'vip', 'Grace Hopper';
SELECT id, fullname, kind, note FROM contacts ORDER BY id;
INSERT INTO contacts (fullname, kind) SELECT upper(lname), 'tag' FROM people WHERE fname = 'Ada';
SELECT fullname, kind FROM contacts WHERE kind = 'tag';
