-- | Execution of one statement against the database.
module Engine.Exec (execute) where

import Data.List (elemIndex, findIndex)
import qualified Data.Sequence as Seq
import Engine.Catalog
import Engine.Compile
import Engine.Error
import Engine.Select (executeSelect)
import Engine.Syntax
import Engine.Value

-- | Run a statement: the new database and the lines it prints, or an error
-- (in which case the caller keeps the old database).
execute :: Database -> Stmt -> Result (Database, [String])
execute db stmt = case stmt of
  CreateTable ifNotExists name cols -> createTable db ifNotExists name cols
  DropTable ifExists name -> dropTable db ifExists name
  Insert name cols rows -> insertRows db name cols rows
  Select sel -> (,) db <$> executeSelect db sel

createTable :: Database -> Bool -> Ident -> [ColumnDef] -> Result (Database, [String])
createTable db ifNotExists name defs = case findTable name db of
  Just _
    | ifNotExists -> Right (db, [])
    | otherwise -> Left (tableExists name)
  Nothing -> do
    checkDuplicates [] defs
    let table = Table name [Column n t | ColumnDef n t <- defs] Seq.empty
    Right (addTable table db, [])
  where
    checkDuplicates _ [] = Right ()
    checkDuplicates seen (ColumnDef n _ : rest)
      | identKey n `elem` seen = Left (duplicateColumn n)
      | otherwise = checkDuplicates (identKey n : seen) rest

dropTable :: Database -> Bool -> Ident -> Result (Database, [String])
dropTable db ifExists name = case findTable name db of
  Just _ -> Right (removeTable name db, [])
  Nothing
    | ifExists -> Right (db, [])
    | otherwise -> Left (noSuchTable name)

insertRows :: Database -> Ident -> Maybe [Ident] -> [[Expr]] -> Result (Database, [String])
insertRows db name listed exprRows = do
  table <- findTable name db `orElse` noSuchTable name
  let columns = tableColumns table
  -- position in the table of each supplied value
  positions <- case listed of
    Nothing -> Right [0 .. length columns - 1]
    Just names -> mapM (\n -> findIndex (\c -> identKey (columnName c) == identKey n) columns
                                `orElse` noColumnNamed name n) names
  let counts = map length exprRows
      supplied = case counts of
        n : _ -> n
        [] -> 0
  if any (/= supplied) counts then Left valuesTermMismatch else Right ()
  if supplied == length positions
    then Right ()
    else Left (case listed of
                 Nothing -> insertCountMismatch name (length columns) supplied
                 Just _ -> insertListMismatch supplied (length positions))
  fns <- mapM (mapM (fmap snd . compileExpr noRowScope)) exprRows
  rows <- mapM (buildRow table positions . map ($ [])) fns
  Right (appendRows name rows db, [])

-- | Place supplied values in column order (unlisted columns are NULL) and
-- convert each to its column's type.
buildRow :: Table -> [Int] -> [Value] -> Result Row
buildRow table positions values = mapM store (zip [0 ..] (tableColumns table))
  where
    store (i, col) = case elemIndex i positions of
      Nothing -> Right VNull
      Just j -> case storeValue (columnType col) (values !! j) of
        Right v -> Right v
        Left rejected ->
          Left (cannotStore rejected (colTypeName (columnType col)) (tableName table) (columnName col))
