-- | Checking and converting one row before it is stored (SPEC 1.5, 2.1).
module Engine.Constraints
  ( RowOrigin (..)
  , validateRow
  , checkExistingUnique
  ) where

import Data.Foldable (toList)
import Data.Maybe (fromMaybe)
import Data.Sequence (Seq)
import Engine.Catalog
import Engine.Error
import Engine.Value

-- | Where a row comes from, which decides how the INTEGER PRIMARY KEY is handled.
data RowOrigin
  = NewRow -- ^ an INSERT: a NULL key gets the next number; every constraint is checked
  | ChangedRow [Int] -- ^ an UPDATE that assigned these columns: NULL key is an error;
  -- uniqueness is rechecked only for constraints that involve them

-- | @validateRow table others origin raw@: @others@ are the table's other rows
-- (without the row being replaced); @raw@ holds one unconverted value per column, then the rowid.
-- Returns the row to store. The first failing check is reported, in the order of SPEC 2.1.
validateRow :: Table -> Seq Row -> RowOrigin -> Row -> Result Row
validateRow table others origin raw = do
  keyed <- keyStep
  mapM_ checkNotNull (zip3 [0 :: Int ..] columns keyed)
  checkKeyUnique keyed
  stored <- mapM storeColumn (zip3 [0 ..] columns keyed)
  mapM_ (checkUnique stored . ukColumns) (reverse (filter (relevant . ukColumns) (tableUniques table)))
  Right (stored ++ [keyed !! rowidIndex table])
  where
    columns = tableColumns table
    name = tableName table
    rowsList = toList others

    touched i = case origin of
      NewRow -> True
      ChangedRow cs -> i `elem` cs
    relevant cs = any touched cs

    -- The rowid (SPEC 7.3) must be an INTEGER, or NULL on insert (next number). With an
    -- INTEGER PRIMARY KEY the key column holds it, and both are kept equal.
    keyStep = do
      let ri = rowidIndex table
          src = fromMaybe ri (tableRowKey table)
      v <- case (raw !! src, origin) of
        (VNull, NewRow) -> Right (VInt nextKey)
        (VNull, _) -> Left datatypeMismatch
        (x, _) -> case storeValue CInteger x of
          Right i@(VInt _) -> Right i
          _ -> Left datatypeMismatch
      Right (take ri (setAt src v raw) ++ [v])
    setAt i v xs = take i xs ++ [v] ++ drop (i + 1) xs
    nextKey = case [i | row <- rowsList, VInt i <- [rowidOfRow row]] of
      [] -> 1
      is -> maximum is + 1

    checkNotNull (i, col, v)
      | columnNotNull col && v == VNull && Just i /= tableRowKey table =
          Left (notNullFailed name (columnName col))
      | otherwise = Right ()

    checkKeyUnique keyed
      | touched (fromMaybe ri (tableRowKey table))
      , any (\row -> compareValues (rowidOfRow row) (keyed !! ri) == EQ) rowsList =
          Left (uniqueFailed name [maybe "rowid" (columnName . (columns !!)) (tableRowKey table)])
      | otherwise = Right ()
      where ri = rowidIndex table

    storeColumn (i, col, v)
      | Just i == tableRowKey table = Right v
      | otherwise = case storeValue (columnType col) v of
          Right v' -> Right v'
          Left rejected ->
            Left (cannotStore rejected (colTypeName (columnType col)) name (columnName col))

    checkUnique stored cs = uniqueConflict table rowsList cs stored

-- | Fails if a row of @others@ equals @row@ on all of the columns @cs@ (none NULL).
uniqueConflict :: Table -> [Row] -> [Int] -> Row -> Result ()
uniqueConflict table others cs row
  | any (== VNull) mine = Right ()
  | any (\o -> and (zipWith (\i v -> compareValues (o !! i) v == EQ) cs mine)) others =
      Left (uniqueFailed (tableName table) [columnName (tableColumns table !! i) | i <- cs])
  | otherwise = Right ()
  where
    mine = map (row !!) cs

-- | Do the rows already in the table respect a uniqueness constraint on @cs@? (CREATE UNIQUE INDEX)
checkExistingUnique :: Table -> [Int] -> Result ()
checkExistingUnique table cs = go [] (toList (tableRows table))
  where
    go _ [] = Right ()
    go before (r : rest) = uniqueConflict table before cs r >> go (r : before) rest
