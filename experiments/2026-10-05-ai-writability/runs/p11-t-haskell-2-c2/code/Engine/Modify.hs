-- | The statements that change rows: INSERT, UPDATE, DELETE (SPEC 1.6, 2.2, 5.4).
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
import Engine.Query (bindWith, selectBinder)
import Engine.Scope
import Engine.Names (foldName)
import Engine.Value

-- | The names an UPDATE / DELETE sees: the target table, by its own name (SPEC 4.2).
tableScope :: Database -> Table -> Scope
tableScope db tbl = newScope (selectBinder db) Nothing [tableSource (tableName tbl) tbl]

findTable :: Database -> String -> Either String Table
findTable db name = case (lookupTable name db, lookupView name db) of
  (Just t, _) -> Right t
  (_, Just v) -> Left ("cannot modify " ++ viewName v ++ " because it is a view")
  _ -> Left ("no such table: " ++ name)

insertRows :: Database -> Maybe With -> String -> Maybe [String] -> InsertSource -> Either String Database
insertRows db with name listed source = do
  case source of
    FromValues (first : rest) | any ((/= length first) . length) rest -> Left "all VALUES must have the same number of terms"
    _ -> Right ()
  tbl <- findTable db name
  -- the source (a select, its WITH) sees the ctes; the table written to is still the real one
  visible <- maybe (Right db) (bindWith db) with
  let cols = tableColumns tbl
  -- for each table column, the position of its value in a source row (Nothing: not given)
  positions <- case listed of
    Nothing -> Right (map Just [0 .. length cols - 1])
    Just names -> do
      idxs <- traverse (columnIndex cols) names
      Right [ findIndex (== i) idxs | i <- [0 .. length cols - 1] ]
  let expected = maybe (length cols) length listed
  candidates <- case source of
    FromValues rows -> Right [ checkCount expected (length row) >> traverse (evaluate visible) row | row <- rows ]
    FromQuery sel -> do
      sq <- selectBinder visible Nothing sel
      checkCount expected (length (sqColumns sq))
      map Right <$> sqRun sq []   -- fully computed before the first row is stored
  -- rows are checked one at a time, each against the table as the earlier rows left it
  final <- foldM (\existing row -> row >>= addRow tbl positions existing) (tableRows tbl) candidates
  Right (setRows name final db)
  where
    columnIndex cols n = case findIndex ((== foldName n) . foldName . colName) cols of
      Just i -> Right i
      Nothing -> Left ("table " ++ name ++ " has no column named " ++ n)
    checkCount expected supplied
      | supplied == expected = Right ()
      | otherwise = Left $ case listed of
          Nothing -> "table " ++ name ++ " has " ++ show expected ++ " columns but " ++ show supplied ++ " values were supplied"
          Just _ -> show supplied ++ " values for " ++ show expected ++ " columns"
    evaluate visible e = evalConstant <$> bindExpr (newScope (selectBinder visible) Nothing []) e
    addRow tbl positions existing values = do
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
  let scope = tableScope db tbl
  targets <- traverse (\(c, _) -> columnPosition (tableColumns tbl) c) sets
  exprs <- traverse (bindExpr scope . snd) sets
  cond <- traverse (bindExpr scope) wh
  let assignments = zip targets exprs          -- a later assignment to a column wins
      step rows i = do
        let old = Seq.index rows i
        if maybe True (\c -> truthOf (evalExpr [old] c) == Just True) cond
          then do
            let new = foldl (\r (t, e) -> setAt t (evalExpr [old] e) r) old assignments
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
  cond <- traverse (bindExpr (tableScope db tbl)) wh
  let keep r = maybe False (\c -> truthOf (evalExpr [r] c) /= Just True) cond
  Right (setRows name (Seq.fromList (filter keep (toList (tableRows tbl)))) db)
