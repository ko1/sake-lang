-- | The statements that change rows: INSERT, UPDATE, DELETE (SPEC 1.6, 2.2).
-- Each returns the new database or an error; on an error nothing has changed.
module Engine.Modify
  ( insertRows
  , updateRows
  , deleteRows
  ) where

import Control.Monad (foldM)
import Data.Foldable (toList)
import Data.List (findIndex)
import qualified Data.Sequence as Seq
import Engine.Ast
import Engine.Catalog
import Engine.Coerce (truthOf)
import Engine.Constraints
import Engine.Expr
import Engine.Names (foldName)
import Engine.Value

findTable :: Database -> String -> Either String Table
findTable db name = maybe (Left ("no such table: " ++ name)) Right (lookupTable name db)

insertRows :: Database -> String -> Maybe [String] -> [[Expr]] -> Either String Database
insertRows db name listed rows = do
  case rows of
    first : rest | any ((/= length first) . length) rest -> Left "all VALUES must have the same number of terms"
    _ -> Right ()
  tbl <- findTable db name
  let cols = tableColumns tbl
  -- for each table column, the position of its value in a VALUES row (Nothing: not given)
  positions <- case listed of
    Nothing -> Right (map Just [0 .. length cols - 1])
    Just names -> do
      idxs <- traverse (columnIndex cols) names
      Right [ findIndex (== i) idxs | i <- [0 .. length cols - 1] ]
  let expected = maybe (length cols) length listed
  -- rows are checked one at a time, each against the table as the earlier rows left it
  final <- foldM (addRow tbl positions expected) (tableRows tbl) rows
  Right (setRows name final db)
  where
    columnIndex cols n = case findIndex ((== foldName n) . foldName . colName) cols of
      Just i -> Right i
      Nothing -> Left ("table " ++ name ++ " has no column named " ++ n)
    addRow tbl positions expected existing row
      | length row /= expected = Left $ case listed of
          Nothing -> "table " ++ name ++ " has " ++ show expected ++ " columns but " ++ show (length row) ++ " values were supplied"
          Just _ -> show (length row) ++ " values for " ++ show expected ++ " columns"
      | otherwise = do
          values <- traverse (\e -> evalExpr [] <$> bindExpr emptyScope e) row
          let given = [ maybe (tableDefaults tbl !! i) (values !!) pos | (i, pos) <- zip [0 ..] positions ]
              raw = [ if Just i == tableRowKey tbl && pos == Nothing then VNull else v
                    | (i, pos, v) <- zip3 [0 ..] positions given ]
          stored <- checkRow Inserting tbl existing raw
          Right (existing Seq.|> stored)

-- | UPDATE: every SET expression sees the row as it was; each changed row is checked
-- against the table as it stands after the rows before it.
updateRows :: Database -> String -> [(String, Expr)] -> Maybe Expr -> Either String Database
updateRows db name sets wh = do
  tbl <- findTable db name
  let scope = Scope (tableColumns tbl) []
  targets <- traverse (\(c, _) -> columnPosition (tableColumns tbl) c) sets
  exprs <- traverse (bindExpr scope . snd) sets
  cond <- traverse (bindExpr scope) wh
  let assignments = zip targets exprs          -- a later assignment to a column wins
      step rows i = do
        let old = Seq.index rows i
        if maybe True (\c -> truthOf (evalExpr old c) == Just True) cond
          then do
            let new = foldl (\r (t, e) -> setAt t (evalExpr old e) r) old assignments
                others = Seq.deleteAt i rows
            stored <- checkRow Updating tbl others new
            Right (Seq.update i stored rows)
          else Right rows
  final <- foldM step (tableRows tbl) [0 .. Seq.length (tableRows tbl) - 1]
  Right (setRows name final db)
  where setAt i v r = take i r ++ [v] ++ drop (i + 1) r

deleteRows :: Database -> String -> Maybe Expr -> Either String Database
deleteRows db name wh = do
  tbl <- findTable db name
  cond <- traverse (bindExpr (Scope (tableColumns tbl) [])) wh
  let keep r = maybe False (\c -> truthOf (evalExpr r c) /= Just True) cond
  Right (setRows name (Seq.fromList (filter keep (toList (tableRows tbl)))) db)
