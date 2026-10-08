-- | Checking one row against its table's constraints (SPEC 2.1), shared by INSERT and UPDATE.
module Engine.Constraints
  ( RowMode(..)
  , checkRow
  , checkExistingRows
  ) where

import Data.Foldable (toList)
import Data.Sequence (Seq)
import Engine.Catalog
import Engine.Coerce (parseNumberText)
import qualified Data.Set as Set
import Engine.Sorting (ValueKey(..))
import Engine.Value

-- | An INSERT numbers a NULL row key itself; an UPDATE rejects it.
data RowMode = Inserting | Updating
  deriving (Eq)

-- | Check a row (its column values, then its rowid) and return it as it is stored. @others@ are the
-- table's other rows (for an UPDATE: without the row being changed). The first failure is reported,
-- in the order of the spec: rowid value, NOT NULL, rowid uniqueness, storage conversion,
-- then the other uniqueness constraints from the last declared to the first.
checkRow :: RowMode -> Table -> Seq [Value] -> [Value] -> Either String [Value]
checkRow mode tbl others row0 = do
  rid <- rowidValue (row0 !! rowidSlot tbl)
  let row1 = case tableRowKey tbl of
        Just k -> take k real0 ++ [VInt rid] ++ drop (k + 1) real0
        Nothing -> real0
  mapM_ checkNotNull (zip3 [0 ..] (tableNotNull tbl) row1)
  if any ((== Just (VInt rid)) . rowidOf) (toList others) then Left rowidFailure else Right ()
  row2 <- sequence [ if Just i == tableRowKey tbl then Right v else coerceForColumn tbl col v
                   | (i, col, v) <- zip3 [0 ..] (tableColumns tbl) row1 ]
  mapM_ (`checkUnique` row2) (reverse (tableUniqueKeys tbl))
  Right (row2 ++ [VInt rid])
  where
    qualified = qualifiedName tbl
    real0 = take (length (tableColumns tbl)) row0
    rowidOf r = case drop (length (tableColumns tbl)) r of
      v : _ -> Just v
      [] -> Nothing
    rowidFailure = "UNIQUE constraint failed: " ++ tableName tbl ++ "."
                   ++ maybe "rowid" (colName . (tableColumns tbl !!)) (tableRowKey tbl)

    -- a NULL rowid of a new row gets the next number, anything else must be an INTEGER
    rowidValue VNull
      | mode == Inserting = Right nextRowid
      | otherwise = Left "datatype mismatch"
    rowidValue v = case (case v of VText s -> maybe v id (parseNumberText s); _ -> v) of
      VInt n -> Right n
      VReal d | d >= -9.223372036854775808e18 && d < 9.223372036854775808e18
              , fromIntegral (truncate d :: Int) == d -> Right (truncate d)
      _ -> Left "datatype mismatch"
    nextRowid = case [ n | r <- toList others, Just (VInt n) <- [rowidOf r] ] of
      [] -> 1
      ns -> maximum ns + 1

    checkNotNull (i, True, VNull) = Left ("NOT NULL constraint failed: " ++ qualified i)
    checkNotNull _ = Right ()

    -- a row with NULL in any listed column never conflicts
    checkUnique cols row
      | any (isNull . (row !!)) cols = Right ()
      | any (\r -> all (\c -> compareValues (r !! c) (row !! c) == EQ) cols) (toList others) =
          Left (uniqueFailure tbl cols)
      | otherwise = Right ()

-- | Does a new uniqueness constraint on these columns hold for the rows already stored?
-- The error is the one an INSERT of the second conflicting row would give.
checkExistingRows :: Table -> [Int] -> Either String ()
checkExistingRows tbl cols = go Set.empty (toList (tableRows tbl))
  where
    go _ [] = Right ()
    go seen (r : rs)
      | any isNull key = go seen rs
      | map ValueKey key `Set.member` seen = Left (uniqueFailure tbl cols)
      | otherwise = go (Set.insert (map ValueKey key) seen) rs
      where key = [ r !! c | c <- cols ]

uniqueFailure :: Table -> [Int] -> String
uniqueFailure tbl cols = "UNIQUE constraint failed: " ++ commaSep [ qualifiedName tbl c | c <- cols ]
  where commaSep = foldr1 (\a b -> a ++ ", " ++ b)

qualifiedName :: Table -> Int -> String
qualifiedName tbl i = tableName tbl ++ "." ++ colName (tableColumns tbl !! i)
