;;; Entry point: reads a SQL script from standard input and runs it (see SPEC.md).
(import (rnrs) (engine script))

(run-script (get-string-all (current-input-port)) (current-output-port))
