require "kramdown"
require "kramdown-parser-gfm"

module Kramdown
  # The subset sakelib/kramdown.sake follows: GFM input without the typographic rewrites.
  def self.to_html(md)
    Document.new(md, input: "GFM", hard_wrap: false, gfm_quirks: [:paragraph_end, :no_auto_typographic],
                 smart_quotes: %w[apos apos quot quot]).to_html
  end
end

def show(label, md)
  puts("== #{label}")
  print(Kramdown.to_html(md))
end

show("headings", <<~MD)
  # Title with *emph* and `code`

  Setext H1
  =========

  Setext H2
  ---------

  ## Second & more ##
  ### Third
  ###### Sixth
  ## Second & more
  # Title with *emph* and `code`
  ####### seven is text
  #no space
MD

show("spans", <<~MD)
  A paragraph with **strong**, *em*, _em2_, __strong2__, `a <b> & c`, a [link](http://x.y/z "ttl") and ![alt text](img.png "img title").
  Line two of the same paragraph.
  Hard break above, and one with a backslash\\
  here. Escaped \\*star\\* \\_under\\_ \\`tick\\` \\[br\\] \\# \\\\.

  Strong fallback **a* and *b** and ***c*** and **d *e* f** and *g **h** i*.

  Under _x_ and __y__ and snake_a_b and _not alnum_x and *not * this and ** no ** and 2*3*4.

  Tick ` a ` and `` a `` and `` `x` `` and ` `, also `unclosed and end.

  Entity &amp; &lt;tag&gt; &quot;q&quot; &copy; &#169; &#xA9; &bogus; and bare & amp, a < b > c.

  "Quotes" 'single' -- dashes --- and ... dots stay as they are.
MD

show("links", <<~MD)
  Link [t](u) [t](u "T") [t](<u v>) [t](u 'S') [t][r] [t][] [r] [nope][x] [b [c] d](u) ![i](s) [![i](s)](u).
  Nested [*em* and `code`](/x) and [a](b(c)) and [q](u "a <b> & \\"c\\"") and <http://auto.link/?a=1&b=2> and <me@example.com>.
  A [missing] reference and a [second] one.

  [r]: /ref
  [t]: /t "TT"
  [Second]: http://second.example/path "Two words"
MD

show("blocks", <<~MD)
  > quoted *text*
  > more
  >
  > second para
  > - quoted list
  > - item
  >
  > > nested quote

  Lazy quote
  > q1
  q2 lazy

      indented code <x>
      line 2

      code 1

      code 2
  lazy code
      code 3

  ```ruby
  def f = 1 & 2
  ```

  ```
  plain fence
  ```

  ~~~
  tilde fence with ``` inside
  ~~~

  ````
  ```
  inner
  ```
  ````

  ```
  empty close missing
MD

show("lists", <<~MD)
  - one
  - two
    - nested a
    - nested b
  - three

  1. first
  2. second
  3. third

  * star
  + plus

  1. one
     1. one-a
     2. one-b
  2. two

     second para of two
  3. three

  - loose

  - list

  - a
    b lazy
  - c

    d
  - e

  1. x
  - y

  * a

    * b

    * c
  * d

  - all

  - loose

  - items

  -   wide marker
      continued
  - tab	after
  - last
  ***
MD

show("rules and boundaries", <<~MD)
  Para
  # ATX after para
  Para2
  Para3
  ```
  fence after para
  ```
  Para4
  - list after para
  Para5
      indented after para
  Para6

  ---

  * * *

  ___

  Not a rule: -- or - - or 1. 2.

  Header
  ======
  Text right after.

  Para
  Header
  ------

  - item
  ---
  after
MD

show("edges", <<~MD)
  trailing blank lines


MD
show("empty", "")
show("one line no newline", "just text")
show("crlf", "a\r\nb\r\n\r\n# h\r\n")
