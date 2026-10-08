-- Recipes, ingredients and a pantry.
CREATE TABLE recipes (rid INTEGER PRIMARY KEY, dish TEXT);
CREATE TABLE needs (rid INTEGER, item TEXT, grams INTEGER, PRIMARY KEY (rid, item));
CREATE TABLE pantry (item TEXT PRIMARY KEY, grams INTEGER);
INSERT INTO recipes (dish) VALUES ('pancakes'), ('omelette'), ('salad'), ('toast');
INSERT INTO needs VALUES (1, 'flour', 200), (1, 'egg', 100), (1, 'milk', 300), (2, 'egg', 150), (2, 'cheese', 50);
INSERT INTO needs VALUES (3, 'lettuce', 100), (3, 'tomato', 80);
INSERT INTO pantry VALUES ('flour', 1000), ('egg', 120), ('milk', 500), ('cheese', 10), ('tomato', 80), ('sugar', 300);
-- what each recipe needs and what is in stock
SELECT dish, item, needs.grams, pantry.grams FROM recipes JOIN needs USING (rid) LEFT JOIN pantry USING (item)
  ORDER BY dish, item;
-- recipes that can be made now
SELECT dish FROM recipes r WHERE EXISTS (SELECT 1 FROM needs WHERE rid = r.rid) AND NOT EXISTS
  (SELECT 1 FROM needs n LEFT JOIN pantry p USING (item) WHERE n.rid = r.rid AND coalesce(p.grams, 0) < n.grams)
  ORDER BY dish;
-- shortfall per recipe
SELECT dish, sum(max(n.grams - coalesce(p.grams, 0), 0)) AS short FROM recipes JOIN needs n USING (rid)
  LEFT JOIN pantry p USING (item) GROUP BY dish ORDER BY short, dish;
-- recipes without any ingredient listed
SELECT dish FROM recipes LEFT JOIN needs USING (rid) WHERE item IS NULL;
-- pantry items no recipe uses
SELECT item FROM pantry WHERE item NOT IN (SELECT item FROM needs) ORDER BY item;
-- ingredients used by more than one recipe
SELECT item, group_concat(dish, '/' ORDER BY dish) FROM needs JOIN recipes USING (rid) GROUP BY item
  HAVING count(*) > 1 ORDER BY item;
-- buy eggs, then check again
UPDATE pantry SET grams = grams + 200 WHERE item = 'egg';
INSERT INTO pantry VALUES ('lettuce', 100);
SELECT dish FROM recipes r WHERE (SELECT count(*) FROM needs n JOIN pantry p USING (item)
  WHERE n.rid = r.rid AND p.grams >= n.grams) = (SELECT count(*) FROM needs WHERE rid = r.rid) ORDER BY dish;
SELECT grams FROM needs JOIN pantry USING (item);
SELECT item FROM needs JOIN pantry USING (item) WHERE rid = 2 ORDER BY item;
INSERT INTO needs VALUES (4, 'bread', 50), (4, 'butter', 10), (4, 'bread', 20);
SELECT count(*) FROM needs WHERE rid = (SELECT rid FROM recipes WHERE dish = 'toast');
