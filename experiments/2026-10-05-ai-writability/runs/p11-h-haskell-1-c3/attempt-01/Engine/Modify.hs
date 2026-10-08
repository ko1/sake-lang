-- | INSERT, UPDATE and DELETE: statements that change the rows of a table.
module Engine.Modify
  ( insertRows
  , updateRows
  , deleteRows
  ) where

import Control.Monad (foldM)
import Data.Foldable (toList)
import Data.List (elemIndex)
import qualified Data.Map.Strict as Map
import Data.Sequence ((|>))
import qualified Data.Sequence as Seq
import Engine.Catalog
import Engine.Compile
import Engine.Constraints
import Engine.Error
import Engine.Query (queryCompiler, queryResult)
import Engine.Syntax
import Engine.Value

type Outcome = Result (Database, [String])

lookupTable :: Database -> Ident -> Result Table
lookupTable db name = case findTable name db of
  Just t -> Right t
  Nothing -> case findView name db of
    Just v -> Left (modifyView (viewName v))
    Nothing -> Left (noSuchTable name)

-- | The scope of a statement that reads the rows of one table; the table is
-- a source for the subqueries in the statement (SPEC 4.2).
tableScopeOf :: Database -> Table -> Scope
tableScopeOf db t = newScope (queryCompiler db) Nothing [Source (Just (tableName t)) cols]
  where
    cols = tableScopeColumns t

truthy :: Maybe RowFn -> Row -> Bool
truthy Nothing _ = True
truthy (Just f) r = truthValue (f [r]) == Just True

insertRows :: Database -> Ident -> Maybe [Ident] -> InsertSource -> Outcome
insertRows db name listed source = do
  table <- lookupTable db name
  let columns = tableColumns table
  -- position in the table of each supplied value
  positions <- case listed of
    Nothing -> Right [0 .. length columns - 1]
    Just names -> mapM (\n -> storeTarget table n `orElse` noColumnNamed name n) names
  let checkCount supplied
        | supplied == length positions = Right ()
        | otherwise = Left (case listed of
            Nothing -> insertCountMismatch name (length columns) supplied
            Just _ -> insertListMismatch supplied (length positions))
  valueRows <- case source of
    InsertValues exprRows -> do
      let counts = map length exprRows
          supplied = case counts of
            n : _ -> n
            [] -> 0
      if any (/= supplied) counts then Left valuesTermMismatch else Right ()
      checkCount supplied
      fns <- mapM (mapM (fmap snd . compileExpr (rootScope (queryCompiler db)))) exprRows
      Right (map (map ($ [[]])) fns)
    InsertSelect query -> do
      (width, rows) <- queryResult db query -- computed in full before any row is stored
      checkCount width
      Right rows
  let rawRow values = [ maybe (defaultFor i c) (values !!) (elemIndex i positions)
                      | (i, c) <- zip [0 ..] columns ]
                      ++ [maybe VNull (values !!) (elemIndex (rowidIndex table) positions)]
      -- a DEFAULT on the INTEGER PRIMARY KEY is ignored (SPEC 2.1)
      defaultFor i c = if Just i == tableRowKey table then VNull else columnDefault c
      addRow rows values = do
        row <- validateRow table rows NewRow (rawRow values)
        Right (rows |> row)
  rows <- foldM addRow (tableRows table) valueRows
  Right (setRows name rows db, [])

updateRows :: Database -> Ident -> [(Ident, Expr)] -> Maybe Expr -> Outcome
updateRows db name assignments wher = do
  table <- lookupTable db name
  let scope = tableScopeOf db table
  targets <- mapM (\(c, _) -> storeTarget table c `orElse` noSuchColumn c) assignments
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
