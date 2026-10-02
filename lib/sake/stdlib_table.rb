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
      ["Symbol", :start_with?, [S], :bool], ["Symbol", :end_with?, [S], :bool], ["Symbol", :casecmp?, ["Symbol"], :bool_nil],
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
      [A, :minmax, [], :tuple_elem_nil2, { conv: :tuple, compare: true }],
      [A, :minmax_by, [], :tuple_elem_nil2, { block: :required, yields: :one, conv: :tuple, compare: true }],
      [A, :one?, [], :bool, { block: :required, yields: :one }],
      [A, :rindex, ["Any"], :int_nil], [A, :values_at, [], :array_elem_nil, { rest: I }],
      [A, :combination, [I], :array_of_arrays, { conv: :to_a }],
      [A, :permutation, [], :array_of_arrays, { opt: [I], conv: :to_a }],
      [A, :chunk_while, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      [A, :slice_when, [], :array_of_arrays, { block: :required, yields: :two, conv: :to_a }],
      [A, :each_entry, [], :recv, { block: :required, yields: :one }],
      [A, :transpose, [], :transpose],
      [A, :union, [], :array_union, { rest: A }], [A, :difference, [], :array, { rest: A }],
      [A, :intersection, [], :array, { rest: A }], [A, :intersect?, [A], :bool],
      [A, :keep_if, [], :recv, { block: :required, yields: :one }],
      [A, :fill, ["Any"], :recv, { check_elems: true }],
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
      ["Set", :min, [], :elem_nil, { compare: true }], ["Set", :max, [], :elem_nil, { compare: true }],
      ["Set", :sort, [], :array, { compare: true }], ["Set", :sort_by, [], :array, { block: :required, yields: :one, compare: true }],
      ["Set", :join, [], S, { opt: [S] }], ["Set", :first, [], :elem_nil],
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
      [H, :update, [H], :recv], [H, :default, [], :hash_default],
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
      # Kernel
      ["Kernel", :sleep, [], I, { opt: [REAL], kernel: true }],
    ].freeze
  end

  module Stdlib
    module_function

    def install_table(reg)
      StdlibTable::ROWS.each do |ns, name, params, _result, opts|
        opts ||= {}
        subject = opts[:kernel] ? [] : [ns]
        reg.define(ns, name, subject + params, optional: opts[:opt] || [], rest: opts[:rest],
                   block: opts[:block] || :none) do |*args, &b|
          table_call(ns, name, args, b, opts)
        end
      end
    end

    def table_call(ns, name, args, b, opts)
      recv = opts[:kernel] ? Kernel : args.shift
      int_range!(recv) if opts[:int_range]
      finite!(recv) if opts[:finite]
      args[0] = Set.new(args[0].to_a.map { key!(_1) }) if opts[:set_arg] && !args[0].is_a?(Set)
      check_elems(recv, [args[0]]) if opts[:check_elems]
      blk = b && table_block(b, opts[:yields])
      result =
        begin
          recv.public_send(opts[:ruby] || name, *args, &blk)
        rescue ::ZeroDivisionError
          raise Fail.new("ZeroDivisionError", "divided by 0")
        rescue ::KeyError => e
          raise Fail.new("KeyError", e.message)
        rescue ::ArgumentError, ::NoMethodError, ::TypeError => e
          raise Fail.new("ArgumentError", opts[:compare] ? "cannot compare the elements" : e.message)
        rescue ::IndexError, ::RangeError => e
          raise Fail.new(e.class.name, e.message)
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
      when :two, :elem_memo, :acc_elem then proc { |x, y| b.(x, y) }
      else proc { |x| b.(x) }
      end
    end

    def array_result(r)
      raise Fail.new("TypeError", "the block must return an Array, got #{Values.describe(r)}") unless r.is_a?(Array)
      r
    end

    def convert(r, conv, _recv, _opts)
      case conv
      when nil then r
      when :tuple then Tuple.new(r.to_a)
      when :tuple_or_nil then r && Tuple.new(r)
      when :tuples then r.map { Tuple.new(_1) }
      when :to_a then r.to_a
      when :set then Set.new(r.to_a.map { key!(_1) })
      when :group then r.each_key { key!(_1) } && r
      when :group_pairs then r.to_h { |k, kvs| [key!(k), kvs.map { |kv| pair(*kv) }] }
      when :partition_pairs then Tuple.new(r.map { |kvs| kvs.map { |kv| pair(*kv) } })
      else raise "BUG: conversion #{conv}"
      end
    end
  end
end
