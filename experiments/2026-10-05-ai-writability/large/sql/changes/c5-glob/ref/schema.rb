require_relative "errors"
require_relative "ast"
require_relative "table"

# The database's named objects: tables, views and indexes (spec 1.4, 2.1, 5.3, 5.6, 5.7), with the
# statements that create, change and drop them. Tables and views share one name space; indexes have
# their own, but may not take a table's or view's name. Names are case-insensitive. A statement that
# raises SqlError leaves the schema as it was: each one checks everything before it changes anything.
# A copy (dup) is independent of the original, which is how a transaction is undone.
class Schema
  # name: as created; columns: the column-name list or nil; select: the query's syntax tree.
  View = Struct.new(:name, :columns, :select)
  # table: the key (downcased current name) of its table; columns: column indexes.
  Index = Struct.new(:name, :table, :columns, :unique)

  def initialize
    @tables = {} # downcased name => Table
    @views = {}  # downcased name => View
    @indexes = {} # downcased name => Index
  end

  def initialize_copy(source)
    super
    @tables = @tables.transform_values(&:dup)
    @views = @views.dup
    @indexes = @indexes.transform_values(&:dup)
  end

  def table(name) = @tables[name.downcase]
  def view(name) = @views[name.downcase]

  # The table an INSERT, UPDATE or DELETE changes.
  def target_table(name)
    view = view(name)
    raise SqlError, "cannot modify #{view.name} because it is a view" if view
    table(name) or raise SqlError, "no such table: #{name}"
  end

  def create_table(stmt)
    return if name_taken?(stmt.name, stmt.if_not_exists)
    seen = {}
    columns = stmt.columns.map do |c|
      raise SqlError, "duplicate column name: #{c.name}" if seen[c.name.downcase]
      seen[c.name.downcase] = true
      new_column(c)
    end
    @tables[stmt.name.downcase] = build_table(stmt, columns)
  end

  def drop_table(stmt)
    view = view(stmt.name)
    raise SqlError, "use DROP VIEW to delete view #{view.name}" if view
    unless table(stmt.name)
      return if stmt.if_exists
      raise SqlError, "no such table: #{stmt.name}"
    end
    key = stmt.name.downcase
    @tables.delete(key)
    @indexes.delete_if { |_, index| index.table == key }
  end

  # CREATE VIEW does not look into its select (5.3): errors there are the using statement's.
  def create_view(stmt)
    return if name_taken?(stmt.name, stmt.if_not_exists)
    @views[stmt.name.downcase] = View.new(stmt.name, stmt.columns, stmt.select)
  end

  def drop_view(stmt)
    table = table(stmt.name)
    raise SqlError, "use DROP TABLE to delete table #{table.name}" if table
    unless view(stmt.name)
      return if stmt.if_exists
      raise SqlError, "no such view: #{stmt.name}"
    end
    @views.delete(stmt.name.downcase)
  end

  # The table is checked first, then the index's name (as SQLite does; IF NOT EXISTS concerns only
  # an index of that name), then the columns and, for a UNIQUE index, the rows.
  def create_index(stmt)
    raise SqlError, "views may not be indexed" if view(stmt.table)
    table = table(stmt.table) or raise SqlError, "no such table: #{stmt.table}"
    raise SqlError, "there is already a table named #{stmt.name}" if table(stmt.name) || view(stmt.name)
    if @indexes.key?(stmt.name.downcase)
      return if stmt.if_not_exists
      raise SqlError, "index #{stmt.name} already exists"
    end
    columns = stmt.columns.map { |name| table.column_index(name) or raise SqlError, "no such column: #{name}" }
    if stmt.unique
      changed = table.dup
      changed.add_unique_index(stmt.name, columns)
      @tables[stmt.table.downcase] = changed
    end
    @indexes[stmt.name.downcase] = Index.new(stmt.name, stmt.table.downcase, columns, stmt.unique)
  end

  def drop_index(stmt)
    index = @indexes[stmt.name.downcase]
    unless index
      return if stmt.if_exists
      raise SqlError, "no such index: #{stmt.name}"
    end
    @tables[index.table].drop_unique_index(index.name) if index.unique
    @indexes.delete(stmt.name.downcase)
  end

  # ALTER TABLE ... ADD COLUMN (5.6): the column's errors in SQLite's order, then the existing rows
  # get its DEFAULT converted as by 1.5.
  def add_column(stmt)
    table = alter_target(stmt.table, "Cannot add a column to a view")
    c = stmt.column
    raise SqlError, "duplicate column name: #{c.name}" if table.column_index(c.name)
    raise SqlError, "Cannot add a PRIMARY KEY column" if c.constraints.include?(:primary_key)
    raise SqlError, "Cannot add a UNIQUE column" if c.constraints.include?(:unique)
    column = new_column(c)
    if column.not_null && column.default.nil? && !table.rows.empty?
      raise SqlError, "Cannot add a NOT NULL column with default value NULL"
    end
    value = table.rows.empty? ? nil : table.convert(column.default, column)
    changed = table.dup
    changed.add_column(column, value)
    @tables[stmt.table.downcase] = changed
  end

  # RENAME TO: the new name may be no table's, view's or index's, the table's own included (as in
  # SQLite); the table's indexes follow it.
  def rename_table(stmt)
    table = alter_target(stmt.table, "view #{view(stmt.table)&.name} may not be altered")
    if table(stmt.new_name) || view(stmt.new_name) || @indexes.key?(stmt.new_name.downcase)
      raise SqlError, "there is already another table or index with this name: #{stmt.new_name}"
    end
    old_key = stmt.table.downcase
    new_key = stmt.new_name.downcase
    changed = table.dup
    changed.name = stmt.new_name
    @tables.delete(old_key)
    @tables[new_key] = changed
    @indexes.transform_values! { |index| index.table == old_key ? Index.new(index.name, new_key, index.columns, index.unique) : index }
  end

  # RENAME COLUMN: constraints and indexes refer to columns by position, so they follow.
  def rename_column(stmt)
    table = alter_target(stmt.table, "cannot rename columns of view \"#{view(stmt.table)&.name}\"")
    i = table.column_index(stmt.column) or raise SqlError, "no such column: \"#{stmt.column}\""
    changed = table.dup
    changed.columns[i].name = stmt.new_name
    @tables[stmt.table.downcase] = changed
  end

  private

  # Whether CREATE TABLE / VIEW of `name` is to do nothing (IF NOT EXISTS and the name is a table's
  # or view's); raises when the name is taken otherwise.
  def name_taken?(name, if_not_exists)
    if (taken = table(name) ? "table" : view(name) && "view")
      return true if if_not_exists
      raise SqlError, "#{taken} #{name} already exists"
    end
    raise SqlError, "there is already an index named #{name}" if @indexes.key?(name.downcase)
    false
  end

  # The table ALTER TABLE changes; view_error: SQLite's message when the name is a view's.
  def alter_target(name, view_error)
    raise SqlError, view_error if view(name)
    table(name) or raise SqlError, "no such table: #{name}"
  end

  def new_column(c)
    default = c.default.equal?(AST::NO_DEFAULT) ? nil : c.default
    Table::Column.new(c.name, c.type, c.constraints.include?(:not_null), default)
  end

  # The table's constraints (spec 2.1) in declaration order: column constraints in column order,
  # then table constraints. A PRIMARY KEY of one INTEGER column is the key; any other is UNIQUE plus
  # NOT NULL on its columns.
  def build_table(stmt, columns)
    declared = []
    stmt.columns.each_with_index do |c, i|
      c.constraints.each { |kind| declared << [kind, [i]] unless kind == :not_null }
    end
    stmt.constraints.each do |constraint|
      indexes = constraint.columns.map do |name|
        columns.index { |column| column.name.downcase == name.downcase } or raise SqlError, "no such column: #{name}"
      end
      declared << [constraint.kind, indexes]
    end
    key_index = nil
    uniques = []
    declared.each do |kind, indexes|
      if kind == :primary_key && indexes.length == 1 && columns[indexes[0]].type == "INTEGER"
        key_index = indexes[0]
        next
      end
      indexes.each { |i| columns[i].not_null = true } if kind == :primary_key
      uniques << Table::Unique.new(indexes)
    end
    Table.new(stmt.name, columns, uniques, key_index)
  end
end
