-- | Statements that create or drop tables, views and indexes (SPEC 1.4, 5.3, 5.7).
-- Tables and views share one name space; index names have their own but may not take a table's name.
module Engine.Schema
  ( createTable
  , dropTable
  , createView
  , dropView
  , createIndex
  , dropIndex
  ) where

import Control.Monad (when)
import Engine.Ast
import Engine.Catalog
import Engine.Constraints (checkExistingRows)
import Engine.Names (foldName)
import Engine.Value (parseCollation)

-- | What a CREATE TABLE / CREATE VIEW does when the name is taken. A table or view of that name is
-- an error (or nothing, with IF NOT EXISTS); an index of that name is always an error.
checkFreeName :: Bool -> String -> Database -> Either String Bool
checkFreeName ifNotExists name db
  | Just _ <- lookupTable name db = taken ("table " ++ name ++ " already exists")
  | Just _ <- lookupView name db = taken ("view " ++ name ++ " already exists")
  | IsIndex `elem` nameTaken name db = Left ("there is already an index named " ++ name)
  | otherwise = Right True
  where taken msg = if ifNotExists then Right False else Left msg

createTable :: Database -> Bool -> String -> [ColumnDef] -> [TableConstraint] -> Either String Database
createTable db ifNotExists name defs cons = do
  free <- checkFreeName ifNotExists name db
  if free then (`insertTable` db) <$> newTable name defs cons else Right db

dropTable :: Database -> Bool -> String -> Either String Database
dropTable db ifExists name = case (lookupTable name db, lookupView name db) of
  (Just _, _) -> Right (removeTable name db)   -- its indexes go with it
  (_, Just v) -> Left ("use DROP VIEW to delete view " ++ viewName v)
  _ | ifExists -> Right db
    | otherwise -> Left ("no such table: " ++ name)

createView :: Database -> Bool -> String -> [String] -> Select -> Either String Database
createView db ifNotExists name cols sel = do
  free <- checkFreeName ifNotExists name db
  Right (if free then insertView (View name cols sel) db else db)

dropView :: Database -> Bool -> String -> Either String Database
dropView db ifExists name = case (lookupView name db, lookupTable name db) of
  (Just _, _) -> Right (removeView name db)
  (_, Just t) -> Left ("use DROP TABLE to delete table " ++ tableName t)
  _ | ifExists -> Right db
    | otherwise -> Left ("no such view: " ++ name)

-- | A UNIQUE index is checked against the rows already stored; a plain one only records its columns.
createIndex :: Database -> Bool -> Bool -> String -> String -> [IndexedColumn] -> Either String Database
createIndex db unique ifNotExists name tableNameWritten colNames = do
  tbl <- case lookupTable tableNameWritten db of
    Just t -> Right t
    Nothing | Just _ <- lookupView tableNameWritten db -> Left "views may not be indexed"
            | otherwise -> Left ("no such table: " ++ tableNameWritten)
  when (any (`elem` [IsTable, IsView]) (nameTaken name db)) $ Left ("there is already a table named " ++ name)
  if IsIndex `elem` nameTaken name db
    then if ifNotExists then Right db else Left ("index " ++ name ++ " already exists")
    else do
      resolved <- traverse (position tbl) colNames
      let cols = map fst resolved
          index = Index name cols (map snd resolved) unique
      when unique $ checkExistingRows tbl resolved
      Right (insertTable tbl { tableIndexes = tableIndexes tbl ++ [index] } db)
  where
    -- the column's position and the collation of the index column: its COLLATE, else the column's own
    position tbl (IndexedColumn c written) = do
      i <- either (const (Left ("table " ++ tableName tbl ++ " has no column named " ++ c))) Right
                  (columnPosition (tableColumns tbl) c)
      coll <- case written of
        Nothing -> Right (colCollation (tableColumns tbl !! i))
        Just n -> maybe (Left ("no such collation sequence: " ++ n)) Right (parseCollation n)
      Right (i, coll)

dropIndex :: Database -> Bool -> String -> Either String Database
dropIndex db ifExists name = case lookupIndex name db of
  Just (tbl, _) ->
    let keep i = foldName (indexName i) /= foldName name
    in Right (insertTable tbl { tableIndexes = filter keep (tableIndexes tbl) } db)
  Nothing | ifExists -> Right db
          | otherwise -> Left ("no such index: " ++ name)
