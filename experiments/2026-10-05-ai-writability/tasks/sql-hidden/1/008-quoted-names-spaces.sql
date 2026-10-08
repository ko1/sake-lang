CREATE TABLE "order lines" ("line no" INTEGER, "unit ""price""" REAL, qty INTEGER);
INSERT INTO "order lines" VALUES (1, 2.5, 4), (2, 10, 1);
SELECT "line no", "unit ""price""" * qty FROM "order lines" ORDER BY "line no";
SELECT "LINE NO" FROM "Order Lines" WHERE "unit ""PRICE""" > 5;
SELECT "QTY" FROM "order lines" ORDER BY 1 DESC;
CREATE TABLE "x""y" (v INTEGER);
INSERT INTO "x""y" VALUES (3);
SELECT v + 1 FROM "X""Y";
SELECT "v" * 2 AS "double v" FROM "x""y";
