-- | The ordering used by ORDER BY (SPEC 1.7), shared by SELECT and by
-- @group_concat(... ORDER BY ...)@, and row equality for DISTINCT and compound selects (SPEC 3.4).
module Engine.Sorting
  ( compareKeys
  , RowKey (..)
  , compareRows
  , dedupeBy
  , groupOn
  ) where

import Data.List (groupBy, sortBy, zipWith4)
import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Engine.Syntax (OrderTerm (..))
import Engine.Value

-- | Compare two rows' sort-key values term by term; each term has the collation for its TEXT values.
compareKeys :: [OrderTerm] -> [Collation] -> [Value] -> [Value] -> Ordering
compareKeys terms colls as bs = mconcat (zipWith4 one terms (colls ++ repeat Binary) as bs)
  where
    one (OrderTerm _ desc nullsFirst) coll a b = case (a, b) of
      (VNull, VNull) -> EQ
      (VNull, _) -> if first then LT else GT
      (_, VNull) -> if first then GT else LT
      _ -> (if desc then flip else id) (compareValuesC coll) a b
      where
        first = fromMaybe (not desc) nullsFirst

-- | Values compared pairwise, each pair under its column's collation (a missing one is BINARY).
compareRows :: [Collation] -> [Value] -> [Value] -> Ordering
compareRows colls as bs = mconcat (zipWith3 compareValuesC (colls ++ repeat Binary) as bs)

-- | A row compared as DISTINCT does: values pairwise equal by 1.9 under the columns' collations, NULLs equal.
data RowKey = RowKey [Collation] [Value]

instance Eq RowKey where
  a == b = compare a b == EQ

instance Ord RowKey where
  compare (RowKey colls as) (RowKey _ bs) = compareRows colls as bs

-- | Keep the first of each group of items with equal keys (under the collations), in order.
dedupeBy :: [Collation] -> (a -> [Value]) -> [a] -> [a]
dedupeBy colls key = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | k `Set.member` seen = go seen xs
      | otherwise = x : go (Set.insert k seen) xs
      where
        k = RowKey colls (key x)

-- | Items grouped by equal key values (NULLs equal, TEXT under the collations), groups in key order and items in input order.
groupOn :: [Collation] -> (a -> [Value]) -> [a] -> [[a]]
groupOn colls key = groupBy (\a b -> compareRows colls (key a) (key b) == EQ) . sortBy (\a b -> compareRows colls (key a) (key b))
