-- | Checking and converting one row before it is stored (SPEC 1.5, 2.1).
module Engine.Constraints
  ( RowOrigin (..)
  , validateRow
  ) where

import Data.Foldable (toList)
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
-- (without the row being replaced); @raw@ holds one unconverted value per column.
-- Returns the row to store. The first failing check is reported, in the order of SPEC 2.1.
validateRow :: Table -> Seq Row -> RowOrigin -> Row -> Result Row
validateRow table others origin raw = do
  keyed <- keyStep
  mapM_ checkNotNull (zip3 [0 :: Int ..] columns keyed)
  checkKeyUnique keyed
  stored <- mapM storeColumn (zip3 [0 ..] columns keyed)
  mapM_ (checkUnique stored) (reverse (filter relevant (tableUniques table)))
  Right stored
  where
    columns = tableColumns table
    name = tableName table
    rowsList = toList others

    touched i = case origin of
      NewRow -> True
      ChangedRow cs -> i `elem` cs
    relevant cs = any touched cs

    -- INTEGER PRIMARY KEY: its value must be an INTEGER, or NULL on insert (next number)
    keyStep = case tableRowKey table of
      Nothing -> Right raw
      Just k -> do
        v <- case (raw !! k, origin) of
          (VNull, NewRow) -> Right (VInt (nextKey k))
          (VNull, _) -> Left datatypeMismatch
          (v, _) -> case storeValue CInteger v of
            Right i@(VInt _) -> Right i
            _ -> Left datatypeMismatch
        Right (take k raw ++ [v] ++ drop (k + 1) raw)
    nextKey k = case [i | row <- rowsList, VInt i <- [row !! k]] of
      [] -> 1
      is -> maximum is + 1

    checkNotNull (i, col, v)
      | columnNotNull col && v == VNull && Just i /= tableRowKey table =
          Left (notNullFailed name (columnName col))
      | otherwise = Right ()

    checkKeyUnique keyed = case tableRowKey table of
      Just k
        | touched k, any (\row -> compareValues (row !! k) (keyed !! k) == EQ) rowsList ->
            Left (uniqueFailed name [columnName (columns !! k)])
      _ -> Right ()

    storeColumn (i, col, v)
      | Just i == tableRowKey table = Right v
      | otherwise = case storeValue (columnType col) v of
          Right v' -> Right v'
          Left rejected ->
            Left (cannotStore rejected (colTypeName (columnType col)) name (columnName col))

    checkUnique stored cs
      | any (== VNull) mine = Right ()
      | any (\row -> and (zipWith (\i v -> compareValues (row !! i) v == EQ) cs mine)) rowsList =
          Left (uniqueFailed name [columnName (columns !! i) | i <- cs])
      | otherwise = Right ()
      where
        mine = map (stored !!) cs
