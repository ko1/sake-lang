-- pi takes no arguments and gives a REAL
SELECT pi(), typeof(pi()), PI(), round(pi(), 2), pi() * 2;
SELECT length(pi()), substr(pi(), 1, 4), pi() || '';
SELECT pi() > 3.14, pi() < 3.15, CAST(pi() AS INTEGER), pi() - 3;
