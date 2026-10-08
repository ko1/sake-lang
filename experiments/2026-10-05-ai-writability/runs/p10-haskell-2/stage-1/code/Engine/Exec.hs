-- | Executes one statement against the database (SPEC 1.4, 1.6). A failing statement changes nothing.
module Engine.Exec
  ( execute
  ) where

import Data.List (findIndex, intercalate)
import Engine.Ast
import Engine.Catalog
import Engine.Expr
import Engine.Names (foldName)
import Engine.Query (runSelect)
import Engine.Value

-- | The new database and the lines to print, or an error message.
execute :: Database -> Statement -> Either String (Database, [String])
execute db stmt = case stmt of
  CreateTable ine name cols -> createTable db ine name cols
  DropTable ie name -> dropTable db ie name
  Insert name cols rows -> insertRows db name cols rows
  SelectStmt sel -> (\rows -> (db, map (joinBar . map textForm) rows)) <$> runSelect db sel
  where joinBar = intercalate "|"

createTable :: Database -> Bool -> String -> [ColumnDef] -> Either String (Database, [String])
createTable db ifNotExists name defs = case lookupTable name db of
  Just _ | ifNotExists -> Right (db, [])
         | otherwise -> Left ("table " ++ name ++ " already exists")
  Nothing -> do
    checkDuplicates [] defs
    let cols = [ Column (cdName d) (cdType d) | d <- defs ]
    Right (insertTable (Table name cols mempty) db, [])
  where
    checkDuplicates _ [] = Right ()
    checkDuplicates seen (d : ds)
      | foldName (cdName d) `elem` seen = Left ("duplicate column name: " ++ cdName d)
      | otherwise = checkDuplicates (foldName (cdName d) : seen) ds

dropTable :: Database -> Bool -> String -> Either String (Database, [String])
dropTable db ifExists name = case lookupTable name db of
  Just _ -> Right (removeTable name db, [])
  Nothing | ifExists -> Right (db, [])
          | otherwise -> Left ("no such table: " ++ name)

insertRows :: Database -> String -> Maybe [String] -> [[Expr]] -> Either String (Database, [String])
insertRows db name listed rows = do
  case rows of
    first : rest | any ((/= length first) . length) rest -> Left "all VALUES must have the same number of terms"
    _ -> Right ()
  tbl <- maybe (Left ("no such table: " ++ name)) Right (lookupTable name db)
  let cols = tableColumns tbl
  -- for each table column, the position of its value in a VALUES row (Nothing: NULL)
  positions <- case listed of
    Nothing -> Right (map Just [0 .. length cols - 1])
    Just names -> do
      idxs <- traverse (columnIndex cols) names
      Right [ findIndex (== i) idxs | i <- [0 .. length cols - 1] ]
  let expected = maybe (length cols) length listed
  stored <- traverse (storeRow tbl positions expected) rows
  Right (appendRows name stored db, [])
  where
    columnIndex cols n = case findIndex ((== foldName n) . foldName . colName) cols of
      Just i -> Right i
      Nothing -> Left ("table " ++ name ++ " has no column named " ++ n)
    storeRow tbl positions expected row
      | length row /= expected = Left $ case listed of
          Nothing -> "table " ++ name ++ " has " ++ show expected ++ " columns but " ++ show (length row) ++ " values were supplied"
          Just _ -> show (length row) ++ " values for " ++ show expected ++ " columns"
      | otherwise = do
          values <- traverse (\e -> evalExpr [] <$> bindExpr emptyScope e) row
          sequence [ coerceForColumn tbl col (maybe VNull (values !!) pos)
                   | (col, pos) <- zip (tableColumns tbl) positions ]
