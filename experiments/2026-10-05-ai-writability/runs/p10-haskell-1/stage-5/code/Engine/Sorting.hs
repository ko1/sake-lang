-- | The ordering used by ORDER BY (SPEC 1.7), shared by SELECT and by
-- @group_concat(... ORDER BY ...)@, and row equality for DISTINCT and compound selects (SPEC 3.4).
module Engine.Sorting
  ( compareKeys
  , RowKey (..)
  , dedupeBy
  ) where

import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Engine.Syntax (OrderTerm (..))
import Engine.Value

-- | Compare two rows' sort-key values term by term.
compareKeys :: [OrderTerm] -> [Value] -> [Value] -> Ordering
compareKeys terms as bs = mconcat (zipWith3 one terms as bs)
  where
    one (OrderTerm _ desc nullsFirst) a b = case (a, b) of
      (VNull, VNull) -> EQ
      (VNull, _) -> if first then LT else GT
      (_, VNull) -> if first then GT else LT
      _ -> (if desc then flip else id) compareValues a b
      where
        first = fromMaybe (not desc) nullsFirst

-- | A row compared as DISTINCT does: values pairwise equal by 1.9, NULLs equal.
newtype RowKey = RowKey [Value]

instance Eq RowKey where
  a == b = compare a b == EQ

instance Ord RowKey where
  compare (RowKey as) (RowKey bs) = mconcat (zipWith compareValues as bs)

-- | Keep the first of each group of items with equal keys, in order.
dedupeBy :: (a -> [Value]) -> [a] -> [a]
dedupeBy key = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | k `Set.member` seen = go seen xs
      | otherwise = x : go (Set.insert k seen) xs
      where
        k = RowKey (key x)
