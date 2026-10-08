-- | Statements that change the schema: CREATE / DROP of tables, views and
-- indexes, and ALTER TABLE (SPEC 1.4, 5.3, 5.6, 5.7).
module Engine.Ddl
  ( createTable
  , dropTable
  , createView
  , dropView
  , createIndex
  , dropIndex
  , alterAddColumn
  , alterRenameTable
  , alterRenameColumn
  ) where

import Data.List (findIndex)
import qualified Data.Sequence as Seq
import Engine.Catalog
import Engine.Constraints (checkExistingUnique)
import Engine.Error
import Engine.Schema (buildTable, makeColumn)
import Engine.Syntax
import Engine.Value

-- | What a name already denotes. Tables and views share a name space; indexes have their own.
data Taken = TakenByTable | TakenByView | TakenByIndex

-- | What a new table or view of this name would collide with.
takenAsRelation :: Database -> Ident -> Maybe Taken
takenAsRelation db name = case (findTable name db, findView name db, lookupIndex name db) of
  (Just _, _, _) -> Just TakenByTable
  (_, Just _, _) -> Just TakenByView
  (_, _, Just _) -> Just TakenByIndex
  _ -> Nothing

-- | Create a table or view named @name@ with the given builder, unless the name is taken.
createRelation :: Database -> Bool -> Ident -> Result Database -> Result Database
createRelation db ifNotExists name build = case takenAsRelation db name of
  Nothing -> build
  Just TakenByTable -> clash (tableExists name)
  Just TakenByView -> clash (viewExists name)
  Just TakenByIndex -> Left (indexNamed name)
  where
    clash err = if ifNotExists then Right db else Left err

createTable :: Database -> Bool -> Ident -> [ColumnDef] -> [TableConstraint] -> Result Database
createTable db ifNotExists name defs constraints =
  createRelation db ifNotExists name (flip addTable db <$> buildTable name defs constraints)

createView :: Database -> Bool -> Ident -> Maybe [Ident] -> Query -> Result Database
createView db ifNotExists name columns query =
  createRelation db ifNotExists name (Right (addView (View name columns query) db))

dropTable :: Database -> Bool -> Ident -> Result Database
dropTable db ifExists name = case (findTable name db, findView name db) of
  (Just _, _) -> Right (removeTable name db)
  (_, Just v) -> Left (dropTableOnView (viewName v))
  _ | ifExists -> Right db
    | otherwise -> Left (noSuchTable name)

dropView :: Database -> Bool -> Ident -> Result Database
dropView db ifExists name = case (findView name db, findTable name db) of
  (Just _, _) -> Right (removeView name db)
  (_, Just t) -> Left (dropViewOnTable (tableName t))
  _ | ifExists -> Right db
    | otherwise -> Left (noSuchView name)

-- | CREATE [UNIQUE] INDEX. A UNIQUE index becomes the table's last uniqueness constraint.
createIndex :: Database -> Bool -> Bool -> Ident -> Ident -> [Ident] -> Result Database
createIndex db unique ifNotExists name tableRef columnNames = do
  table <- case findTable tableRef db of
    Just t -> Right t
    Nothing | Just _ <- findView tableRef db -> Left (viewNotIndexed tableRef)
            | otherwise -> Left (noSuchTable tableRef)
  case (findTable name db, findView name db, lookupIndex name db) of
    (Just _, _, _) -> Left (tableNamed name)
    (_, Just _, _) -> Left (tableNamed name)
    (_, _, Just _) | ifNotExists -> Right db
                   | otherwise -> Left (indexExists name)
    _ -> do
      positions <- mapM (position table) columnNames
      if unique
        then do
          checkExistingUnique table positions
          let table' = table {tableUniques = tableUniques table ++ [UniqueKey positions (Just name)]}
          Right (addIndex (Index name (tableName table)) (replaceTable (tableName table) table' db))
        else Right (addIndex (Index name (tableName table)) db)
  where
    position table c =
      findIndex (\col -> identKey (columnName col) == identKey c) (tableColumns table)
        `orElse` noColumnNamed (tableName table) c

-- | DROP INDEX; a UNIQUE index takes its constraint with it.
dropIndex :: Database -> Bool -> Ident -> Result Database
dropIndex db ifExists name = case lookupIndex name db of
  Nothing | ifExists -> Right db
          | otherwise -> Left (noSuchIndex name)
  Just index ->
    let db' = removeIndex name db
     in Right $ case findTable (indexTable index) db' of
          Just t -> replaceTable (tableName t) t {tableUniques = filter (not . declaredBy) (tableUniques t)} db'
          Nothing -> db'
  where
    declaredBy uk = fmap identKey (ukIndex uk) == Just (identKey name)

-- | The table an ALTER TABLE names.
alterable :: Database -> Ident -> Result Table
alterable db name = case findTable name db of
  Just t -> Right t
  Nothing | Just v <- findView name db -> Left (viewNotAlterable (viewName v))
          | otherwise -> Left (noSuchTable name)

alterAddColumn :: Database -> Ident -> ColumnDef -> Result Database
alterAddColumn db tableRef def@(ColumnDef name _ constraints) = do
  table <- alterable db tableRef
  if any ((== identKey name) . identKey . columnName) (tableColumns table)
    then Left (duplicateColumn name) else Right ()
  if CPrimaryKey `elem` constraints then Left addPrimaryKeyColumn else Right ()
  if CUnique `elem` constraints then Left addUniqueColumn else Right ()
  if columnNotNull column && columnDefault column == VNull && not (Seq.null (tableRows table))
    then Left addNotNullColumn else Right ()
  let stored = either (const (columnDefault column)) id (storeValue (columnType column) (columnDefault column))
      table' = table { tableColumns = tableColumns table ++ [column]
                     , tableRows = fmap (++ [stored]) (tableRows table) }
  Right (replaceTable (tableName table) table' db)
  where
    column = makeColumn def

alterRenameTable :: Database -> Ident -> Ident -> Result Database
alterRenameTable db tableRef new = do
  table <- alterable db tableRef
  case takenAsRelation db new of
    Nothing -> Right (replaceTable (tableName table) table {tableName = new} db)
    Just _ -> Left (renameTaken new)

alterRenameColumn :: Database -> Ident -> Ident -> Ident -> Result Database
alterRenameColumn db tableRef old new = do
  table <- alterable db tableRef
  i <- findIndex ((== identKey old) . identKey . columnName) (tableColumns table)
         `orElse` noSuchColumnQuoted old
  let rename j c = if j == i then c {columnName = new} else c
  Right (replaceTable (tableName table) table {tableColumns = zipWith rename [0 ..] (tableColumns table)} db)
