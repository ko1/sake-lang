CREATE TABLE step (seq INTEGER PRIMARY KEY, recipe TEXT, action TEXT, mins REAL);
INSERT INTO step (recipe, action, mins) VALUES ('soup','chop',5),('soup','boil',20.5),('soup','serve',1),('tea','boil',3),('tea','steep',4.5);
SELECT recipe, action, lag(action) OVER (PARTITION BY recipe ORDER BY seq), lead(action) OVER (PARTITION BY recipe ORDER BY seq) FROM step ORDER BY seq;
SELECT action, lead(mins) OVER (ORDER BY seq), typeof(lag(mins) OVER (ORDER BY seq)) FROM step ORDER BY seq;
SELECT recipe || ':' || action || '->' || lead(action, 1, 'done') OVER (PARTITION BY recipe ORDER BY seq) FROM step ORDER BY seq;
SELECT action, lag(upper(action), 1, '') OVER (ORDER BY action, seq) FROM step ORDER BY action, seq;
