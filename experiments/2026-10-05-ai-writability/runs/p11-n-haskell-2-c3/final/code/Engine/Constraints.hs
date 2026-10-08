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

-- | Check a row and return it as it is stored. The row is the table's columns, then the rowid slot
-- (SPEC 7.3); for a table with an INTEGER PRIMARY KEY the rowid is that column's value and the
-- trailing slot is filled from it. @others@ are the table's other rows (for an UPDATE: without the
-- row being changed). The first failure is reported, in the order of the spec: rowid value, NOT NULL,
-- rowid uniqueness, storage conversion, then the other uniqueness constraints from the last declared
-- to the first.
checkRow :: RowMode -> Table -> Seq [Value] -> [Value] -> Either String [Value]
checkRow mode tbl others row0 = do
  row1 <- keyValueFixed
  mapM_ checkNotNull (zip3 [0 ..] (tableNotNull tbl) row1)
  checkUnique [ridPos] row1
  converted <- sequence [ if Just i == tableRowKey tbl then Right v else coerceForColumn tbl col v
                        | (i, col, v) <- zip3 [0 ..] (tableColumns tbl) row1 ]
  let row2 = converted ++ [row1 !! ridPos]
  mapM_ (`checkUnique` row2) (reverse (tableUniqueKeys tbl))
  Right row2
  where
    qualified = qualifiedName tbl
    ridPos = rowIdPosition tbl

    -- the rowid: a NULL gets the next number, anything else must be an INTEGER
    keyValueFixed = do
      v <- keyValue (row0 !! ridPos)
      Right (take ridPos row0 ++ [v] ++ drop (ridPos + 1) row0)
    keyValue VNull
      | mode == Inserting = Right (VInt nextKey)
      | otherwise = Left "datatype mismatch"
    keyValue v = case (case v of VText s -> maybe v id (parseNumberText s); _ -> v) of
      VInt n -> Right (VInt n)
      VReal d | d >= -9.223372036854775808e18 && d < 9.223372036854775808e18
              , fromIntegral (truncate d :: Int) == d -> Right (VInt (truncate d))
      _ -> Left "datatype mismatch"
    nextKey = case [ n | r <- toList others, VInt n <- [r !! ridPos] ] of
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
qualifiedName tbl i
  | i >= length (tableColumns tbl) = tableName tbl ++ ".rowid"
  | otherwise = tableName tbl ++ "." ++ colName (tableColumns tbl !! i)
