-- | ALTER TABLE (SPEC 5.6): add a column, rename the table, rename a column.
-- Constraints and indexes refer to columns by position, so they follow a rename by themselves.
module Engine.Alter
  ( alterTable
  ) where

import Engine.Ast
import Engine.Catalog
import Engine.Names (foldName)
import Engine.Value (isNull)

alterTable :: Database -> String -> AlterAction -> Either String Database
alterTable db name action = case lookupTable name db of
  Nothing -> Left ("no such table: " ++ name)
  Just tbl -> case action of
    AddColumn def -> (`insertTable` db) <$> addColumn tbl def
    RenameTable new -> renameTable db tbl new
    RenameColumn old new -> (\t -> insertTable t db) <$> renameColumn tbl old new

addColumn :: Table -> ColumnDef -> Either String Table
addColumn tbl def = do
  checkNewName
  if any isPrimaryKey constraints then Left "Cannot add a PRIMARY KEY column" else Right ()
  if any isUnique constraints then Left "Cannot add a UNIQUE column" else Right ()
  if notNull && isNull dflt && not (null (tableRows tbl))
    then Left "Cannot add a NOT NULL column with default value NULL" else Right ()
  let column = Column (cdName def) (cdType def)
      grown = tbl { tableColumns = tableColumns tbl ++ [column]
                  , tableNotNull = tableNotNull tbl ++ [notNull]
                  , tableDefaults = tableDefaults tbl ++ [dflt] }
  stored <- coerceForColumn grown column dflt
  Right grown { tableRows = fmap (++ [stored]) (tableRows tbl) }
  where
    constraints = cdConstraints def
    notNull = any isNotNull constraints
    dflt = columnDefault def
    checkNewName
      | any ((== foldName (cdName def)) . foldName . colName) (tableColumns tbl) = Left ("duplicate column name: " ++ cdName def)
      | otherwise = Right ()
    isPrimaryKey c = case c of CPrimaryKey -> True; _ -> False
    isUnique c = case c of CUnique -> True; _ -> False
    isNotNull c = case c of CNotNull -> True; _ -> False

renameTable :: Database -> Table -> String -> Either String Database
renameTable db tbl new
  | not (null (nameTaken new db)) = Left ("there is already another table or index with this name: " ++ new)
  | otherwise = Right (replaceTable (tableName tbl) tbl { tableName = new } db)

renameColumn :: Table -> String -> String -> Either String Table
renameColumn tbl old new = case [ i | (i, c) <- zip [0 :: Int ..] (tableColumns tbl), foldName (colName c) == foldName old ] of
  [] -> Left ("no such column: \"" ++ old ++ "\"")
  i : _ -> Right tbl { tableColumns = [ if j == i then c { colName = new } else c | (j, c) <- zip [0 ..] (tableColumns tbl) ] }
