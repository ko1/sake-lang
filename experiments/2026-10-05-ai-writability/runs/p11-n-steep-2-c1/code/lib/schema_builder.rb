module MiniSql
  # Turns a CREATE TABLE statement into a Table: column constraints, the row key and the
  # UNIQUE keys in declaration order (column constraints first, then table constraints).
  module SchemaBuilder
    def self.build(statement)
      defs = statement.columns
      names = defs.map { |definition| definition.name.downcase(:ascii) }
      names.each_with_index do |name, i|
        raise SqlError, "duplicate column name: #{defs.fetch(i).name}" if names.index(name) != i
      end
      primary = primary_key_positions(statement, names)
      key_index = primary.length == 1 && defs.fetch(primary.fetch(0)).type == :integer ? primary.fetch(0) : nil
      unique_keys = [] # @type var unique_keys: Array[UniqueKey]
      defs.each_with_index do |definition, i|
        unique_keys << UniqueKey.new([i], [definition.collation]) if definition.unique
        unique_keys << UniqueKey.new([i], [definition.collation]) if definition.primary_key && key_index != i
      end
      statement.constraints.each do |constraint|
        positions = positions_of(constraint.columns, names)
        next if constraint.kind == :primary && key_index
        unique_keys << UniqueKey.new(positions, positions.map { |position| defs.fetch(position).collation })
      end
      columns = defs.each_with_index.map do |definition, i|
        Column.new(definition.name, definition.type, definition.not_null || primary.include?(i), definition.default,
                    definition.collation)
      end
      rows = [] # @type var rows: Array[Array[sql_value]]
      Table.new(statement.name, columns, key_index, unique_keys, rows)
    end

    # Positions of the PRIMARY KEY columns (empty when there is none).
    def self.primary_key_positions(statement, names)
      constraint = statement.constraints.find { |c| c.kind == :primary }
      return positions_of(constraint.columns, names) if constraint
      positions = [] # @type var positions: Array[Integer]
      statement.columns.each_with_index { |definition, i| positions << i if definition.primary_key }
      positions
    end

    def self.positions_of(columns, names)
      columns.map { |name| names.index(name.downcase(:ascii)) || raise(SqlError, "no such column: #{name}") }
    end
  end
end
