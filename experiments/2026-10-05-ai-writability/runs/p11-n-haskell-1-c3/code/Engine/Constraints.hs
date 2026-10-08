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
-- (without the row being replaced); @raw@ holds one unconverted value per column
-- followed by the rowid's value (NULL when none is given). A row is stored as its
-- column values followed by its rowid. Returns the row to store. The first
-- failing check is reported, in the order of SPEC 7.3.
validateRow :: Table -> Seq Row -> RowOrigin -> Row -> Result Row
validateRow table others origin raw = do
  rowid <- rowidStep
  let keyed = case tableRowKey table of
        Nothing -> columnValues
        Just k -> take k columnValues ++ [rowid] ++ drop (k + 1) columnValues
  mapM_ checkNotNull (zip3 [0 :: Int ..] columns keyed)
  checkRowidUnique rowid
  stored <- mapM storeColumn (zip3 [0 ..] columns keyed)
  mapM_ (checkUnique stored . ukColumns) (reverse (filter (relevant . ukColumns) (tableUniques table)))
  Right (stored ++ [rowid])
  where
    columns = tableColumns table
    name = tableName table
    rowsList = toList others
    columnValues = take (length columns) raw

    -- where the rowid's value is held in @raw@: the INTEGER PRIMARY KEY column, or the extra slot
    rowidSlot = fromMaybe (length columns) (tableRowKey table)

    touched i = case origin of
      NewRow -> True
      ChangedRow cs -> i `elem` cs
    relevant cs = any touched cs

    -- the rowid must be an INTEGER; NULL on insert means the next number
    rowidStep = case (raw !! rowidSlot, origin) of
      (VNull, NewRow) -> Right (VInt (nextRowid))
      (VNull, _) -> Left datatypeMismatch
      (v, _) -> case storeValue CInteger v of
        Right i@(VInt _) -> Right i
        _ -> Left datatypeMismatch
    nextRowid = case [i | row <- rowsList, VInt i <- [last row]] of
      [] -> 1
      is -> maximum is + 1

    checkNotNull (i, col, v)
      | columnNotNull col && v == VNull && Just i /= tableRowKey table =
          Left (notNullFailed name (columnName col))
      | otherwise = Right ()

    checkRowidUnique rowid
      | touched rowidSlot, any (\row -> compareValues (last row) rowid == EQ) rowsList =
          Left (uniqueFailed name [maybe "rowid" (columnName . (columns !!)) (tableRowKey table)])
      | otherwise = Right ()

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
