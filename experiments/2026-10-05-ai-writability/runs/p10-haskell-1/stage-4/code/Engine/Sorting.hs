-- | The ordering used by ORDER BY (SPEC 1.7), shared by SELECT and by
-- @group_concat(... ORDER BY ...)@.
module Engine.Sorting (compareKeys) where

import Data.Maybe (fromMaybe)
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
