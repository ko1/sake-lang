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
import Engine.Sorting (valueKey)
import Engine.Value

-- | An INSERT numbers a NULL row key itself; an UPDATE rejects it.
data RowMode = Inserting | Updating
  deriving (Eq)

-- | Check a row and return it as it is stored. @others@ are the table's other rows
-- (for an UPDATE: without the row being changed). The first failure is reported,
-- in the order of the spec: row key, NOT NULL, row key uniqueness, storage conversion,
-- then the other uniqueness constraints from the last declared to the first.
checkRow :: RowMode -> Table -> Seq [Value] -> [Value] -> Either String [Value]
checkRow mode tbl others row0 = do
  row1 <- keyValueFixed
  mapM_ checkNotNull (zip3 [0 ..] (tableNotNull tbl) row1)
  maybe (Right ()) (\k -> checkUnique [(k, Binary)] row1) (tableRowKey tbl)
  row2 <- sequence [ if Just i == tableRowKey tbl then Right v else coerceForColumn tbl col v
                   | (i, col, v) <- zip3 [0 ..] (tableColumns tbl) row1 ]
  mapM_ (`checkUnique` row2) (reverse (tableUniqueKeys tbl))
  Right row2
  where
    qualified = qualifiedName tbl

    -- the INTEGER PRIMARY KEY: a NULL gets the next number, anything else must be an INTEGER
    keyValueFixed = case tableRowKey tbl of
      Nothing -> Right row0
      Just k -> do
        v <- keyValue (row0 !! k)
        Right (take k row0 ++ [v] ++ drop (k + 1) row0)
    keyValue VNull
      | mode == Inserting = Right (VInt (nextKey (tableRowKey tbl)))
      | otherwise = Left "datatype mismatch"
    keyValue v = case (case v of VText s -> maybe v id (parseNumberText s); _ -> v) of
      VInt n -> Right (VInt n)
      VReal d | d >= -9.223372036854775808e18 && d < 9.223372036854775808e18
              , fromIntegral (truncate d :: Int) == d -> Right (VInt (truncate d))
      _ -> Left "datatype mismatch"
    nextKey (Just k) = case [ n | r <- toList others, VInt n <- [r !! k] ] of
      [] -> 1
      ns -> maximum ns + 1
    nextKey Nothing = 1

    checkNotNull (i, True, VNull) = Left ("NOT NULL constraint failed: " ++ qualified i)
    checkNotNull _ = Right ()

    -- a row with NULL in any listed column never conflicts; each column is compared under its own collation
    checkUnique cols row
      | any (isNull . (row !!) . fst) cols = Right ()
      | any (\r -> all (\(c, coll) -> compareValuesC coll (r !! c) (row !! c) == EQ) cols) (toList others) =
          Left (uniqueFailure tbl (map fst cols))
      | otherwise = Right ()

-- | Does a new uniqueness constraint on these columns hold for the rows already stored?
-- The error is the one an INSERT of the second conflicting row would give.
checkExistingRows :: Table -> [(Int, Collation)] -> Either String ()
checkExistingRows tbl cols = go Set.empty (toList (tableRows tbl))
  where
    go _ [] = Right ()
    go seen (r : rs)
      | any isNull [ r !! c | (c, _) <- cols ] = go seen rs
      | key `Set.member` seen = Left (uniqueFailure tbl (map fst cols))
      | otherwise = go (Set.insert key seen) rs
      where key = [ valueKey coll (r !! c) | (c, coll) <- cols ]

uniqueFailure :: Table -> [Int] -> String
uniqueFailure tbl cols = "UNIQUE constraint failed: " ++ commaSep [ qualifiedName tbl c | c <- cols ]
  where commaSep = foldr1 (\a b -> a ++ ", " ++ b)

qualifiedName :: Table -> Int -> String
qualifiedName tbl i = tableName tbl ++ "." ++ colName (tableColumns tbl !! i)
