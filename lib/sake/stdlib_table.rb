# frozen_string_literal: true

module Sake
  # Built-in operations that delegate to the Ruby method of the same name. One row drives both the
  # interpreter and the type inference (Typer#table_result):
  #   [namespace, name, params, result, options]
  # params: types of the arguments after the subject; options:
  #   opt:  optional parameter types       rest: type of extra arguments
  #   block: :required / :optional         yields: how a block receives values (see TABLE_YIELDS)
  #   conv: how to convert Ruby's result (see Stdlib.convert)
  #   ruby: the Ruby method when the name differs
  #   on: a Ruby class whose class method it is (no subject: `Dir.children(path)`)
  #   io: a failing system call is IOError, as File.read      keywords: name => type
  # result: a type name, or a symbol interpreted by Typer#table_result.
  module StdlibTable
    S = "String"
    I = "Integer"
    A = "Array"
    H = "Hash"
    REAL = %w[Integer Float Rational].freeze

    ROWS = [
      # String
      [S, :chop, [], S], [S, :chr, [], S], [S, :delete_prefix, [S], S], [S, :delete_suffix, [S], S],
      [S, :codepoints, [], "Array<Integer>"], [S, :bytesize, [], I], [S, :getbyte, [I], :int_nil],
      [S, :ascii_only?, [], :bool], [S, :tr_s, [S, S], S], [S, :casecmp, [S], :int_nil],
      [S, :between?, [S, S], :bool], [S, :clamp, [S, S], S], [S, :rindex, [%w[String Regexp]], :int_nil],
      [S, :partition, [%w[String Regexp]], :tuple3_string, { conv: :tuple }],
      [S, :rpartition, [%w[String Regexp]], :tuple3_string, { conv: :tuple }],
      [S, :to_r, [], "Rational"], [S, :to_c, [], "Complex"],
      [S, :each_byte, [], :recv, { block: :required, yields: :one, yield_type: I }],
      [S, :upto, [S], :recv, { block: :required, yields: :one, yield_type: S }],
      # Symbol
      ["Symbol", :upcase, [], "Symbol"], ["Symbol", :downcase, [], "Symbol"], ["Symbol", :capitalize, [], "Symbol"],
      ["Symbol", :swapcase, [], "Symbol"], ["Symbol", :succ, [], "Symbol"], ["Symbol", :empty?, [], :bool],
      ["Symbol", :start_with?, [S], :bool], ["Symbol", :end_with?, [S], :bool], ["Symbol", :casecmp?, ["Symbol"], :bool, { conv: :bool }],
      # Integer / Float / Rational
      [I, :ceildiv, [I], I, { zero_div: true }], [I, :div, [REAL], I, { zero_div: true }],
      [I, :modulo, [I], I, { zero_div: true }], [I, :remainder, [I], I, { zero_div: true }],
      [I, :floor, [], I, { opt: [I] }], [I, :ceil, [], I, { opt: [I] }], [I, :round, [], I, { opt: [I] }],
      [I, :truncate, [], I, { opt: [I] }], [I, :allbits?, [I], :bool], [I, :anybits?, [I], :bool],
      [I, :nobits?, [I], :bool], [I, :magnitude, [], I], [I, :next, [], I], [I, :to_i, [], I],
      [I, :positive?, [], :bool], [I, :negative?, [], :bool], [I, :ord, [], I],
      [I, :gcdlcm, [I], :tuple_int2, { conv: :tuple }],
      [I, :step, [I, I], :recv, { block: :required, yields: :one, yield_type: I }],
      ["Float", :fdiv, [REAL], "Float"], ["Float", :modulo, [REAL], "Float", { zero_div: true }],
      ["Float", :quo, [REAL], "Float"], ["Float", :positive?, [], :bool], ["Float", :negative?, [], :bool],
      ["Float", :zero?, [], :bool], ["Float", :next_float, [], "Float"], ["Float", :prev_float, [], "Float"],
      ["Float", :magnitude, [], "Float"], ["Float", :between?, %w[Float Float], :bool],
      ["Float", :to_f, [], "Float"],
      ["Rational", :positive?, [], :bool], ["Rational", :negative?, [], :bool],
      # Array
      [A, :collect, [], :array_block, { block: :required, yields: :one, ruby: :map }],
      [A, :find_all, [], :array, { block: :required, yields: :one }],
      [A, :filter_map, [], :array_block_truthy, { block: :required, yields: :one }],
      [A, :take_while, [], :array, { block: :required, yields: :one }],
      [A, :drop_while, [], :array, { block: :required, yields: :one }],
      [A, :each_index, [], :recv, { block: :required, yields: :one, yield_type: I }],
      [A, :reverse_each, [], :recv, { block: :required, yields: :one }],
      [A, :minmax, [], :tuple_elem_nil2, { conv: :tuple, compare: true }], # nil for an empty Array: a miss (level 3)
      [A, :minmax_by, [], :tuple_elem_nil2, { block: :required, yields: :one, conv: :tuple, compare: true }],
      [A, :one?, [], :bool, { block: :required, yields: :one }],
      [A, :rindex, ["Any"], :int_nil], [A, :values_at, [], :array_elem_nil, { rest: I }],
      [A, :combination, [I], :array_of_arrays, { conv: :to_a }],
      [A, :permutation, [], :array_of_arrays, { opt: [I], conv: :to_a }],
      [A, :chunk_while, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      [A, :slice_when, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      [A, :each_entry, [], :recv, { block: :required, yields: :one }],
      [A, :transpose, [], :transpose, { tuple_rows: true }],
      [A, :union, [], :array_union, { rest: A }], [A, :difference, [], :array, { rest: A }],
      [A, :intersection, [], :array, { rest: A }], [A, :intersect?, [A], :bool],
      [A, :keep_if, [], :recv, { block: :required, yields: :one }],
      [A, :fill, ["Any"], :recv, { check_elems: :one }],
      [A, :bsearch, [], :elem_nil, { block: :required, yields: :one }],
      [A, :to_set, [], :set_elem, { conv: :set }],
      # Range
      [ "Range", :each_slice, [I], :recv, { block: :required, yields: :slice, int_range: true }],
      [ "Range", :each_cons, [I], :recv, { block: :required, yields: :slice, int_range: true }],
      [ "Range", :each_with_object, ["Any"], :memo, { block: :required, yields: :elem_memo, int_range: true }],
      [ "Range", :filter_map, [], :array_block_truthy, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :flat_map, [], :array_flat, { block: :required, yields: :one_array, int_range: true, finite: true }],
      [ "Range", :find_index, [], :int_nil, { block: :required, yields: :one, int_range: true }],
      [ "Range", :group_by, [], :hash_group, { block: :required, yields: :one, int_range: true, finite: true, conv: :group }],
      [ "Range", :partition, [], :tuple_arrays, { block: :required, yields: :one, int_range: true, finite: true, conv: :tuple }],
      [ "Range", :take, [I], :array, { int_range: true }], [ "Range", :take_while, [], :array, { block: :required, yields: :one, int_range: true }],
      [ "Range", :drop, [I], :array, { int_range: true, finite: true }],
      [ "Range", :min_by, [], :elem_nil, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :max_by, [], :elem_nil, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :sort_by, [], :array, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :tally, [], :hash_tally, { int_range: true, finite: true }],
      [ "Range", :zip, [], :array_zip, { rest: A, int_range: true, finite: true, conv: :tuples }],
      [ "Range", :to_set, [], :set_elem, { int_range: true, finite: true, conv: :set }],
      [ "Range", :one?, [], :bool, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :reverse_each, [], :recv, { block: :required, yields: :one, int_range: true, finite: true }],
      [ "Range", :overlap?, ["Range"], :bool],
      # Set
      ["Set", :delete?, ["Any"], :recv_nil], ["Set", :subtract, ["Any"], :recv, { set_arg: true }],
      ["Set", :merge, ["Set"], :recv], ["Set", :proper_subset?, ["Set"], :bool], ["Set", :proper_superset?, ["Set"], :bool],
      ["Set", :any?, [], :bool, { block: :required, yields: :one }], ["Set", :all?, [], :bool, { block: :required, yields: :one }],
      ["Set", :none?, [], :bool, { block: :required, yields: :one }],
      ["Set", :count, [], I, { block: :optional, yields: :one }], ["Set", :sum, [], :elem_sum, { opt: [%w[Integer Float Rational Complex]] }],
      ["Set", :min, [], :elem_index_nil, { compare: true }], ["Set", :max, [], :elem_index_nil, { compare: true }],
      ["Set", :sort, [], :array, { compare: true }], ["Set", :sort_by, [], :array, { block: :required, yields: :one, compare: true }],
      ["Set", :join, [], S, { opt: [S] }], ["Set", :first, [], :elem_index_nil],
      ["Set", :find, [], :elem_nil, { block: :required, yields: :one }],
      ["Set", :partition, [], :tuple_arrays, { block: :required, yields: :one, conv: :tuple }],
      ["Set", :reduce, ["Any"], :fold, { block: :required, yields: :acc_elem }],
      ["Set", :each_with_object, ["Any"], :memo, { block: :required, yields: :elem_memo }],
      ["Set", :filter_map, [], :array_block_truthy, { block: :required, yields: :one }],
      ["Set", :delete_if, [], :recv, { block: :required, yields: :one }], ["Set", :keep_if, [], :recv, { block: :required, yields: :one }],
      ["Set", :clear, [], :recv],
      # Hash
      [H, :compact, [], :hash_compact], [H, :except, [], :hash_same, { rest: "Any" }], [H, :slice, [], :hash_same, { rest: "Any" }],
      [H, :values_at, [], :array_val_nil, { rest: "Any" }],
      [H, :fetch_values, [], :array_val, { rest: "Any", key_error: true }],
      [H, :update, [H], :recv_merge], [H, :default, [], :hash_default],
      [H, :delete_if, [], :recv, { block: :required, yields: :pair }], [H, :keep_if, [], :recv, { block: :required, yields: :pair }],
      [H, :shift, [], :pair_nil, { conv: :tuple_or_nil }], [H, :first, [], :pair_nil, { conv: :tuple_or_nil }],
      [H, :take, [I], :array_pairs, { conv: :tuples }], [H, :drop, [I], :array_pairs, { conv: :tuples }],
      [H, :filter_map, [], :array_block_truthy, { block: :required, yields: :pair }],
      [H, :flat_map, [], :array_flat, { block: :required, yields: :pair_array }],
      [H, :group_by, [], :hash_group, { block: :required, yields: :pair, conv: :group_pairs }],
      [H, :partition, [], :tuple_pair_arrays, { block: :required, yields: :pair, conv: :partition_pairs }],
      [H, :one?, [], :bool, { block: :required, yields: :pair }],
      [H, :each_with_object, ["Any"], :memo, { block: :required, yields: :pair_memo }],
      [H, :reduce, ["Any"], :fold, { block: :required, yields: :acc_pair }],
      [H, :inject, ["Any"], :fold, { block: :required, yields: :acc_pair }],
      # Time
      ["Time", :mday, [], I], ["Time", :mon, [], I], ["Time", :nsec, [], I], ["Time", :usec, [], I],
      ["Time", :utc?, [], :bool], ["Time", :zone, [], :string_nil], ["Time", :utc_offset, [], I],
      ["Time", :iso8601, [], S, { opt: [I] }], ["Time", :round, [], "Time", { opt: [I] }],
      ["Time", :floor, [], "Time", { opt: [I] }], ["Time", :ceil, [], "Time", { opt: [I] }],
      *%i[sunday? monday? tuesday? wednesday? thursday? friday? saturday?].map { ["Time", _1, [], :bool] },
      ["Time", :getutc, [], "Time"], ["Time", :gmtime, [], "Time", { ruby: :getutc }],
      ["Time", :getlocal, [], "Time", { opt: [[S, I]] }],
      ["Time", :localtime, [], "Time", { opt: [[S, I]], ruby: :getlocal }],
      ["Time", :gmt_offset, [], I], ["Time", :gmtoff, [], I], ["Time", :gmt?, [], :bool],
      # Kernel
      ["Kernel", :sleep, [], I, { opt: [REAL], kernel: true }],
      # Dir and File: class methods of Ruby's Dir and File
      *[[:children, [S], "Array<String>"], [:entries, [S], "Array<String>"], [:exist?, [S], :bool],
        [:empty?, [S], :bool], [:mkdir, [S], I, { opt: [I] }], [:rmdir, [S], I], [:unlink, [S], I, { ruby: :rmdir }],
        [:pwd, [], S], [:home, [], S, { opt: [S] }], [:tmpdir, [], S],
        [:glob, [[S, A]], "Array<String>", { keywords: { "base" => S } }],
        [:each_child, [S], "Nil", { block: :required, yields: :one, yield_type: S, conv: :nil }]].map do |name, ps, r, o = {}|
        ["Dir", name, ps, r, { on: Dir, io: true, **o }]
      end,
      *[[:directory?, [S], :bool], [:file?, [S], :bool], [:symlink?, [S], :bool], [:zero?, [S], :bool],
        [:empty?, [S], :bool], [:readable?, [S], :bool], [:writable?, [S], :bool], [:executable?, [S], :bool],
        [:absolute_path?, [S], :bool], [:identical?, [S, S], :bool],
        [:size, [S], I], [:mtime, [S], "Time"], [:atime, [S], "Time"], [:ftype, [S], S],
        [:rename, [S, S], I], [:symlink, [S, S], I], [:link, [S, S], I], [:readlink, [S], S],
        [:unlink, [S], I, { rest: S }], [:chmod, [I], I, { rest: S }],
        [:utime, [%w[Time Nil], %w[Time Nil]], I, { rest: S }],
        [:expand_path, [S], S, { opt: [S] }], [:absolute_path, [S], S, { opt: [S] }], [:realpath, [S], S, { opt: [S] }],
        [:basename, [S], S, { opt: [S] }], [:dirname, [S], S, { opt: [I] }], [:extname, [S], S],
        [:split, [S], :tuple_string2, { conv: :tuple }], [:join, [], S, { rest: [S, A] }]].map do |name, ps, r, o = {}|
        ["File", name, ps, r, { on: File, io: true, **o }]
      end,
      # --- 2026-10-09: the rest of Ruby's core API (experiments/2026-10-09-stdlib-port) ---
      # Integer / Float / Rational / Complex
      [I, :denominator, [], I], [I, :numerator, [], I], [I, :integer?, [], :bool], [I, :size, [], I], [I, :to_int, [], I],
      [I, :rationalize, [], "Rational", { opt: [REAL] }],
      ["Float", :arg, [], :int_float], ["Float", :angle, [], :int_float], ["Float", :phase, [], :int_float],
      ["Float", :denominator, [], I, { finite_float: true }], ["Float", :numerator, [], I, { finite_float: true }], ["Float", :to_int, [], I, { finite_float: true }],
      ["Rational", :fdiv, [REAL], "Float"], ["Rational", :magnitude, [], "Rational"], ["Rational", :quo, [%w[Integer Rational]], "Rational", { zero_div: true }],
      ["Rational", :rationalize, [], "Rational", { opt: ["Rational"] }], ["Rational", :to_r, [], "Rational"],
      ["Complex", :abs2, [], :real_part], ["Complex", :arg, [], "Float"], ["Complex", :angle, [], "Float"], ["Complex", :phase, [], "Float"],
      ["Complex", :conj, [], "Complex"], ["Complex", :denominator, [], I], ["Complex", :fdiv, [REAL], "Complex"],
      ["Complex", :finite?, [], :bool], ["Complex", :infinite?, [], :int_nil], ["Complex", :imag, [], :real_part],
      ["Complex", :magnitude, [], :int_float, { conv: :rational_to_f }], ["Complex", :numerator, [], "Complex"], ["Complex", :quo, [REAL + ["Complex"]], "Complex", { zero_div: true }],
      ["Complex", :rationalize, [], "Rational", { opt: ["Rational"] }], ["Complex", :real?, [], :bool],
      ["Complex", :rect, [], :tuple_real2, { conv: :tuple }], ["Complex", :to_c, [], "Complex"],
      ["Complex", :to_f, [], "Float"], ["Complex", :to_i, [], I], ["Complex", :to_r, [], "Rational"],
      # String: the in-place forms give the String back, or nil when nothing changed (Ruby)
      *%i[capitalize! downcase! upcase! swapcase! lstrip! rstrip! strip! chop!].map { [S, _1, [], :recv_nil] },
      [S, :chomp!, [], :recv_nil, { opt: [S] }], [S, :delete!, [S], :recv_nil, { rest: S }], [S, :squeeze!, [], :recv_nil, { rest: S }],
      [S, :delete_prefix!, [S], :recv_nil], [S, :delete_suffix!, [S], :recv_nil], [S, :tr!, [S, S], :recv_nil], [S, :tr_s!, [S, S], :recv_nil],
      [S, :succ!, [], :recv], [S, :next!, [], :recv, { ruby: :succ! }], [S, :reverse!, [], :recv], [S, :scrub!, [], :recv, { opt: [S] }],
      [S, :unicode_normalize!, [], :recv, { opt: ["Symbol"] }],
      [S, :append_as_bytes, [], :recv, { rest: [S, I] }], [S, :byterindex, [[S, "Regexp"]], :int_nil, { opt: [I] }],
      [S, :bytesplice, [I, I, S], :recv], [S, :clear, [], :recv], [S, :concat, [], :recv, { rest: [S, I] }],
      [S, :crypt, [S], S], [S, :dump, [], S], [S, :undump, [], S],
      [S, :each_codepoint, [], :recv, { block: :required, yields: :one, yield_type: I }],
      [S, :each_grapheme_cluster, [], :recv, { block: :required, yields: :one, yield_type: S }],
      [S, :encode, [S], S, { opt: [S] }], [S, :grapheme_clusters, [], "Array<String>"],
      [S, :insert, [I, S], :recv], [S, :prepend, [], :recv, { rest: S }], [S, :replace, [S], :recv],
      [S, :scrub, [], S, { opt: [S] }], [S, :setbyte, [I, I], I], [S, :sum, [], I, { opt: [I] }],
      [S, :unicode_normalize, [], S, { opt: ["Symbol"] }], [S, :unicode_normalized?, [], :bool, { opt: ["Symbol"] }],
      # Symbol
      ["Symbol", :casecmp, ["Symbol"], :int_nil], ["Symbol", :encoding, [], S, { conv: :encoding }], ["Symbol", :id2name, [], S],
      ["Symbol", :name, [], S], ["Symbol", :next, [], "Symbol"], ["Symbol", :intern, [], "Symbol", { ruby: :to_sym }],
      ["Symbol", :slice, [I], :string_nil, { opt: [I] }], ["Symbol", :match, [["Regexp", S]], :matchdata_nil], ["Symbol", :match?, [["Regexp", S]], :bool],
      # Array
      [A, :bsearch_index, [], :int_nil, { block: :required, yields: :one }],
      [A, :cycle, [I], "Nil", { block: :required, yields: :one }], [A, :dig, [I], :dig, { rest: "Any" }],
      [A, :rfind, [], :elem_nil, { block: :required, yields: :one }], # the impl is in install_more_array (Ruby 4.0's rfind)
      [A, :fetch_values, [], :array, { rest: I }],
      [A, :repeated_combination, [I], :array_of_arrays, { conv: :to_a }], [A, :repeated_permutation, [I], :array_of_arrays, { conv: :to_a }],
      [A, :reverse!, [], :recv], [A, :rotate!, [], :recv, { opt: [I] }], [A, :shuffle!, [], :recv],
      [A, :sort!, [], :recv, { compare: true }], [A, :sort_by!, [], :recv, { block: :required, yields: :one, compare: true }],
      [A, :to_a, [], :recv], [A, :uniq!, [], :recv_nil], [A, :compact!, [], :recv_nil],
      [A, :select!, [], :recv_nil, { block: :required, yields: :one }], [A, :filter!, [], :recv_nil, { block: :required, yields: :one }],
      [A, :reject!, [], :recv_nil, { block: :required, yields: :one }],
      [A, :flatten!, [], :recv_flatten], [A, :replace, [A], :recv_elems_of, { check_elems: :all }],
      # Hash
      [H, :assoc, ["Any"], :pair_nil, { conv: :tuple_or_nil }], [H, :rassoc, ["Any"], :pair_nil, { conv: :tuple_or_nil }],
      [H, :compact!, [], :recv_nil], [H, :flatten, [], :array_kv],
      [H, :select!, [], :recv_nil, { block: :required, yields: :pair }], [H, :filter!, [], :recv_nil, { block: :required, yields: :pair }],
      [H, :reject!, [], :recv_nil, { block: :required, yields: :pair }],
      [H, :merge!, [H], :recv_merge], [H, :replace, [H], :recv_merge], [H, :to_h, [], :recv],
      [H, :transform_values!, [], :recv_write_val, { block: :required, yields: :val }],
      # Set: Ruby's Enumerable
      ["Set", :chunk_while, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      ["Set", :slice_when, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      ["Set", :slice_after, [], :array_of_arrays, { block: :required, yields: :one, conv: :to_a }],
      ["Set", :slice_before, [], :array_of_arrays, { block: :required, yields: :one, conv: :to_a }],
      ["Set", :classify, [], :hash_classify, { block: :required, yields: :one, conv: :group }],
      ["Set", :collect, [], :array_block, { block: :required, yields: :one, ruby: :map }],
      ["Set", :flat_map, [], :array_flat, { block: :required, yields: :one_array }],
      ["Set", :collect_concat, [], :array_flat, { block: :required, yields: :one_array, ruby: :flat_map }],
      ["Set", :compact, [], :array], ["Set", :cycle, [I], "Nil", { block: :required, yields: :one }],
      ["Set", :detect, [], :elem_nil, { block: :required, yields: :one }],
      ["Set", :drop, [I], :array], ["Set", :take, [I], :array],
      ["Set", :drop_while, [], :array, { block: :required, yields: :one }], ["Set", :take_while, [], :array, { block: :required, yields: :one }],
      ["Set", :each_cons, [I], :recv, { block: :required, yields: :slice }], ["Set", :each_slice, [I], :recv, { block: :required, yields: :slice }],
      ["Set", :each_entry, [], :recv, { block: :required, yields: :one }],
      ["Set", :each_with_index, [], :recv, { block: :required, yields: :with_index }],
      ["Set", :entries, [], :array], ["Set", :find_all, [], :array, { block: :required, yields: :one }],
      ["Set", :find_index, [], :int_nil, { block: :required, yields: :one }], ["Set", :flatten, [], :set_elem],
      ["Set", :group_by, [], :hash_group, { block: :required, yields: :one, conv: :group }],
      ["Set", :inject, ["Any"], :fold, { block: :required, yields: :acc_elem }],
      ["Set", :max_by, [], :elem_index_nil, { block: :required, yields: :one, compare: true }],
      ["Set", :min_by, [], :elem_index_nil, { block: :required, yields: :one, compare: true }],
      ["Set", :minmax, [], :tuple_elem_nil2, { conv: :tuple, compare: true }],
      ["Set", :minmax_by, [], :tuple_elem_nil2, { block: :required, yields: :one, conv: :tuple, compare: true }],
      ["Set", :one?, [], :bool, { block: :required, yields: :one }],
      ["Set", :reject!, [], :recv_nil, { block: :required, yields: :one }], ["Set", :select!, [], :recv_nil, { block: :required, yields: :one }],
      ["Set", :filter!, [], :recv_nil, { block: :required, yields: :one }],
      ["Set", :replace, ["Set"], :recv_set_elems_of], ["Set", :reverse_each, [], :recv, { block: :required, yields: :one }],
      ["Set", :tally, [], :hash_tally], ["Set", :to_set, [], :recv], ["Set", :uniq, [], :array],
      ["Set", :zip, [], :array_zip, { rest: A, conv: :tuples }],
      # Range: the rest of Enumerable (a Range of Integers or Strings; finite where the whole Range is walked)
      ["Range", :bsearch, [], :elem_nil, { block: :required, yields: :one, int_range: true }],
      ["Range", :chunk_while, [], :array_of_arrays, { block: :required, yields: :two, int_range: true, finite: true, conv: :to_a }],
      ["Range", :slice_when, [], :array_of_arrays, { block: :required, yields: :two, int_range: true, finite: true, conv: :to_a }],
      ["Range", :slice_after, [], :array_of_arrays, { block: :required, yields: :one, int_range: true, finite: true, conv: :to_a }],
      ["Range", :slice_before, [], :array_of_arrays, { block: :required, yields: :one, int_range: true, finite: true, conv: :to_a }],
      ["Range", :collect, [], :array_block, { block: :required, yields: :one, int_range: true, finite: true, ruby: :map }],
      ["Range", :collect_concat, [], :array_flat, { block: :required, yields: :one_array, int_range: true, finite: true, ruby: :flat_map }],
      ["Range", :compact, [], :array, { int_range: true, finite: true }],
      ["Range", :cycle, [I], "Nil", { block: :required, yields: :one, int_range: true, finite: true }],
      ["Range", :drop_while, [], :array, { block: :required, yields: :one, int_range: true }],
      ["Range", :each_entry, [], :recv, { block: :required, yields: :one, int_range: true }],
      ["Range", :entries, [], :array, { int_range: true, finite: true }],
      ["Range", :find_all, [], :array, { block: :required, yields: :one, int_range: true, finite: true }],
      ["Range", :minmax, [], :tuple_elem_nil2, { finite: true, conv: :tuple }],
      ["Range", :minmax_by, [], :tuple_elem_nil2, { block: :required, yields: :one, int_range: true, finite: true, conv: :tuple }],
      ["Range", :sort, [], :array, { int_range: true, finite: true }], ["Range", :uniq, [], :array, { int_range: true, finite: true }],
      # Regexp / MatchData
      ["Regexp", :casefold?, [], :bool], ["Regexp", :encoding, [], S, { conv: :encoding }], ["Regexp", :fixed_encoding?, [], :bool],
      ["Regexp", :named_captures, [], :hash_names_ints], ["Regexp", :names, [], "Array<String>"], ["Regexp", :options, [], I],
      ["Regexp", :timeout, [], :float_nil], ["Regexp", :union, [], "Regexp", { on: Regexp, rest: [S, "Regexp", A] }],
      ["MatchData", :bytebegin, [I], :int_index_nil], ["MatchData", :byteend, [I], :int_index_nil],
      ["MatchData", :byteoffset, [I], :tuple_int_index_nil2, { conv: :tuple }], ["MatchData", :offset, [I], :tuple_int_index_nil2, { conv: :tuple }],
      ["MatchData", :length, [], I], ["MatchData", :size, [], I], ["MatchData", :match, [I], :string_index_nil],
      ["MatchData", :match_length, [I], :int_index_nil], ["MatchData", :regexp, [], "Regexp"], ["MatchData", :string, [], S],
      ["MatchData", :values_at, [], :array_string_nil, { rest: I }],
      # Time
      ["Time", :asctime, [], S], ["Time", :ctime, [], S], ["Time", :dst?, [], :bool], ["Time", :isdst, [], :bool],
      ["Time", :getgm, [], "Time"], ["Time", :subsec, [], :int_rational], ["Time", :to_a, [], :time_to_a, { conv: :tuple }],
      ["Time", :to_r, [], "Rational"], ["Time", :tv_nsec, [], I], ["Time", :tv_sec, [], I], ["Time", :tv_usec, [], I],
      # Time.xmlschema is left to sakelib/time.sake, where one function parses a String and formats a Time
      # (Ruby's class method and instance method share the name; Time.iso8601 formats here).
      # Math (the rest of Ruby's module functions)
      *%i[acos asin sinh cosh tanh asinh acosh atanh erf erfc gamma].map { ["Math", _1, [REAL], "Float", { on: Math }] },
      ["Math", :ldexp, [REAL, I], "Float", { on: Math }],
      ["Math", :frexp, [REAL], :tuple_float_int, { on: Math, conv: :tuple }], ["Math", :lgamma, [REAL], :tuple_float_int, { on: Math, conv: :tuple }],
      # Kernel / Process
      ["Kernel", :srand, [], I, { opt: [I], kernel: true }],
      ["Process", :pid, [], I, { on: Process }], ["Process", :clock_gettime, [I], :clock, { on: Process, opt: ["Symbol"] }],
      # ENV: Ruby's ENV["X"] is ENV.get("X"); ENV["X"] = v is ENV.set("X", v)
      ["ENV", :get, [S], :string_nil, { on: ENV, ruby: :[] }], ["ENV", :fetch, [S], S, { on: ENV, opt: [S], key_error: true }],
      ["ENV", :key?, [S], :bool, { on: ENV }], ["ENV", :set, [S, S], S, { on: ENV, ruby: :[]= }],
      ["ENV", :delete, [S], :string_nil, { on: ENV }], ["ENV", :keys, [], "Array<String>", { on: ENV }],
      ["ENV", :to_h, [], :hash_string_string, { on: ENV }],
    ].freeze
  end

  module Stdlib
    # Range operations that walk the values (TypeError unless the Range starts with an Integer or a String).
    RANGE_ITERATING = (%w[each each_with_index step to_a map select filter reject any? all? none? find detect reduce inject sum size count] +
                       StdlibTable::ROWS.filter_map { |r| r[1].to_s if r[0] == "Range" && r[4]&.[](:int_range) }).map { "Range.#{_1}" }.freeze
    module_function

    def install_table(reg)
      StdlibTable::ROWS.each do |ns, name, params, _result, opts|
        opts ||= {}
        subject = opts[:kernel] || opts[:on] ? [] : [ns]
        reg.define(ns, name, subject + params, optional: opts[:opt] || [], rest: opts[:rest],
                   block: opts[:block] || :none, keywords: opts[:keywords] || {}) do |*args, **kw, &b|
          opts[:io] ? io_error { table_call(ns, name, args, b, opts, kw) } : table_call(ns, name, args, b, opts, kw)
        end
      end
    end

    def table_call(ns, name, args, b, opts, kw = {})
      recv = opts[:kernel] ? Kernel : opts[:on] || args.shift
      int_range!(recv) if opts[:int_range]
      finite!(recv) if opts[:finite]
      if opts[:set_arg] && !args[0].is_a?(Set)
        raise Fail.new("TypeError", "argument 2 must be Set, Array, Tuple, or Range, got #{Values.describe(args[0])}") unless args[0].is_a?(Array) || args[0].is_a?(Tuple) || args[0].is_a?(Range)
        args[0] = Set.new((args[0].is_a?(Tuple) ? args[0].elems : args[0].to_a).map { key!(_1) })
      end
      check_elems(recv, opts[:check_elems] == :all ? args[0].to_a : [args[0]]) if opts[:check_elems]
      recv = recv.map { _1.is_a?(Tuple) ? _1.elems : _1 } if opts[:tuple_rows]
      raise Fail.new("FloatDomainError", recv.to_s) if opts[:finite_float] && !recv.finite?
      blk = b && table_block(b, opts[:yields])
      result =
        begin
          recv.public_send(opts[:ruby] || name, *args, **kw, &blk)
        rescue ::ZeroDivisionError
          raise Fail.new("ZeroDivisionError", "divided by 0")
        rescue ::KeyError => e
          raise Fail.new("KeyError", e.message)
        rescue ::FrozenError
          raise Fail.new("TypeError", FROZEN_STRING)
        rescue ::Math::DomainError => e
          raise Fail.new("Math::DomainError", e.message)
        rescue ::ArgumentError => e
          raise Fail.new("ArgumentError", opts[:compare] ? "cannot compare the elements" : e.message)
        rescue ::NoMethodError, ::TypeError => e
          raise Fail.new("TypeError", opts[:compare] ? "cannot compare the elements" : e.message.sub(/ for an instance of (\w+)\z/) { " of #{Values.display_type($1)}" })
        rescue ::IndexError, ::RangeError => e
          raise Fail.new(e.class.name, e.message)
        rescue ::SystemCallError => e # an argument the system refuses (ENV.set("", v), an unknown clock)
          raise Fail.new(opts[:io] ? "IOError" : "ArgumentError", e.message)
        end
      convert(result, opts[:conv], recv, opts)
    end

    def table_block(b, yields)
      case yields
      when :pair then proc { |k, v| b.(pair(k, v)) }
      when :one_array then proc { |x| array_result(b.(x)) }
      when :pair_array then proc { |k, v| array_result(b.(pair(k, v))) }
      when :pair_memo then proc { |(k, v), memo| b.(pair(k, v), memo) }
      when :acc_pair then proc { |acc, (k, v)| b.(acc, pair(k, v)) }
      when :two, :elem_memo, :acc_elem, :with_index then proc { |x, y| b.(x, y) }
      else proc { |x| b.(x) }
      end
    end

    # The block's result for flat_map: an Array, or a Tuple (`[k, v]` is natural there).
    def array_result(r)
      return r.elems if r.is_a?(Tuple)
      raise Fail.new("TypeError", "the block must return an Array or a Tuple, got #{Values.describe(r)}") unless r.is_a?(Array)
      r
    end

    def convert(r, conv, _recv, _opts)
      case conv
      when nil then r
      when :tuple then Tuple.new(r.to_a)
      when :tuple_or_nil then r && Tuple.new(r)
      when :nil then nil
      when :tuples then r.map { Tuple.new(_1) }
      when :to_a then r.to_a
      when :set then Set.new(r.to_a.map { key!(_1) })
      when :group then r.each_key { key!(_1) } && r
      when :group_pairs then r.to_h { |k, kvs| [key!(k), kvs.map { |kv| pair(*kv) }] }
      when :partition_pairs then Tuple.new(r.map { |kvs| kvs.map { |kv| pair(*kv) } })
      when :encoding then r.name
      when :bool then !!r
      when :rational_to_f then r.is_a?(Rational) ? r.to_f : r
      else raise "BUG: conversion #{conv}"
      end
    end
  end
end
