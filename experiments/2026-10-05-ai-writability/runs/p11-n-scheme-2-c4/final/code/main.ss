#!r6rs
;;; Entry point: run the SQL script on standard input, print results to standard output.
(import (rnrs) (engine exec))

(let ([in (transcoded-port (standard-input-port) (make-transcoder (utf-8-codec)))]
      [out (current-output-port)])
  (run-script (get-string-all in) out)
  (flush-output-port out))
