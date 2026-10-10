#!/bin/sh
# Builds docs/manual/build/index.html (both languages) with ligarb (https://github.com/ko1/ligarb).
# The reference chapters (ja/ref, en/ref) are checked against the interpreter by tools/check_reference.rb.
set -e
cd "$(dirname "$0")"
ligarb build book.yml
