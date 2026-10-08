SELECT length(X'00'), length(X'000000'), length(X''), length(x'deadbeef');
SELECT length(CAST('hello' AS BLOB)), length(CAST(-12 AS BLOB)), length(CAST(NULL AS BLOB));
