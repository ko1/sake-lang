-- | Ordering and equality of rows of values: ORDER BY (SPEC 1.7), DISTINCT and GROUP BY keys (SPEC 3.3, 3.4).
module Engine.Sorting
  ( compareByTerms
  , ValueKey(..)
  , distinctOn
  ) where

import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Engine.Ast (NullsPos(..), OrderTerm(..))
import Engine.Value

-- | Compare two rows of sort-key values term by term; NULLs sort first under ASC and last
-- under DESC unless NULLS FIRST / LAST says otherwise.
compareByTerms :: [OrderTerm] -> [Value] -> [Value] -> Ordering
compareByTerms terms ka kb = mconcat (zipWith3 cmp terms ka kb)
  where
    cmp term a b = case (isNull a, isNull b) of
      (True, True) -> EQ
      (True, False) -> if nullsFirst then LT else GT
      (False, True) -> if nullsFirst then GT else LT
      _ -> (if otDesc term then flip else id) compareValues a b
      where nullsFirst = fromMaybe (if otDesc term then NullsLast else NullsFirst) (otNulls term) == NullsFirst

-- | A value that is equal to another when 'compareValues' says so (NULL equals NULL), so it can key a Set or Map.
newtype ValueKey = ValueKey Value

instance Eq ValueKey where
  a == b = compare a b == EQ

instance Ord ValueKey where
  compare (ValueKey a) (ValueKey b) = compareValues a b

-- | Keep the first element for each key, in the original order.
distinctOn :: Ord k => (a -> k) -> [a] -> [a]
distinctOn key = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | k `Set.member` seen = go seen xs
      | otherwise = x : go (Set.insert k seen) xs
      where k = key x
