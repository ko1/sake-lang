-- shipping: boxes are paid per started kilogram; leftover pieces after full pallets
CREATE TABLE parcel (id INTEGER PRIMARY KEY, dest TEXT, weight REAL, pieces INTEGER);
INSERT INTO parcel (dest, weight, pieces) VALUES
  ('north', 1.2, 14), ('south', 3.0, 30), ('north', 0.4, 5), ('east', 2.75, 9), ('south', 5.01, 41);
SELECT id, dest, ceil(weight) AS paid_kg, mod(pieces, 12) AS loose FROM parcel ORDER BY id;
SELECT dest, sum(ceil(weight)), count(*) FROM parcel GROUP BY dest ORDER BY dest;
SELECT ceil(weight) AS band, count(*) FROM parcel GROUP BY band ORDER BY band;
-- side of a square box holding the volume, and the cost growing with the square of the distance
SELECT id, sqrt(pieces), pow(id, 2) * 1.5 FROM parcel WHERE mod(pieces, 2) = 1 ORDER BY id;
SELECT id, sum(ceil(weight)) OVER (ORDER BY id) FROM parcel ORDER BY id;
