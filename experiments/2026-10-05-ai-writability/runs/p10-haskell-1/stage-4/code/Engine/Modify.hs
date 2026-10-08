-- | INSERT, UPDATE and DELETE: statements that change the rows of a table.
module Engine.Modify
  ( insertRows
  , updateRows
  , deleteRows
  ) where

import Control.Monad (foldM)
import Data.Foldable (toList)
import Data.List (elemIndex, findIndex)
import qualified Data.Map.Strict as Map
import Data.Sequence ((|>))
import qualified Data.Sequence as Seq
import Engine.Catalog
import Engine.Compile
import Engine.Constraints
import Engine.Error
import Engine.Select (subqueryCompiler)
import Engine.Syntax
import Engine.Value

type Outcome = Result (Database, [String])

lookupTable :: Database -> Ident -> Result Table
lookupTable db name = findTable name db `orElse` noSuchTable name

-- | The scope of a statement that reads the rows of one table; the table is
-- a source for the subqueries in the statement (SPEC 4.2).
tableScopeOf :: Database -> Table -> Scope
tableScopeOf db t = newScope (subqueryCompiler db) Nothing [Source (Just (tableName t)) cols]
  where
    cols = [ScopeColumn (columnName c) (Just (columnType c)) False | c <- tableColumns t]

truthy :: Maybe RowFn -> Row -> Bool
truthy Nothing _ = True
truthy (Just f) r = truthValue (f [r]) == Just True

insertRows :: Database -> Ident -> Maybe [Ident] -> [[Expr]] -> Outcome
insertRows db name listed exprRows = do
  table <- lookupTable db name
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
  fns <- mapM (mapM (fmap snd . compileExpr (rootScope (subqueryCompiler db)))) exprRows
  let rawRow values = [ maybe (columnDefault c) (values !!) (elemIndex i positions)
                      | (i, c) <- zip [0 ..] columns ]
      addRow rows values = do
        row <- validateRow table rows NewRow (rawRow values)
        Right (rows |> row)
  rows <- foldM addRow (tableRows table) (map (map ($ [[]])) fns)
  Right (setRows name rows db, [])

updateRows :: Database -> Ident -> [(Ident, Expr)] -> Maybe Expr -> Outcome
updateRows db name assignments wher = do
  table <- lookupTable db name
  let scope = tableScopeOf db table
      columns = tableColumns table
  targets <- mapM (\(c, _) -> findIndex (\k -> identKey (columnName k) == identKey c) columns
                                `orElse` noSuchColumn c) assignments
  fns <- mapM (fmap snd . compileExpr scope . snd) assignments
  whereFn <- traverse (fmap snd . compileExpr scope) wher
  let lastWins = Map.toList (Map.fromList (zip targets fns)) -- a column named twice keeps the last
      changed = map fst lastWins
      step rows i
        | not (truthy whereFn old) = Right rows
        | otherwise = do
            new <- validateRow table (Seq.deleteAt i rows) (ChangedRow changed) raw
            Right (Seq.update i new rows)
        where
          old = Seq.index rows i
          raw = [ maybe v (\f -> f [old]) (lookup j lastWins) | (j, v) <- zip [0 ..] old ]
  rows <- foldM step (tableRows table) [0 .. Seq.length (tableRows table) - 1]
  Right (setRows name rows db, [])

deleteRows :: Database -> Ident -> Maybe Expr -> Outcome
deleteRows db name wher = do
  table <- lookupTable db name
  whereFn <- traverse (fmap snd . compileExpr (tableScopeOf db table)) wher
  let kept = Seq.fromList [r | r <- toList (tableRows table), not (truthy whereFn r)]
  Right (setRows name kept db, [])
