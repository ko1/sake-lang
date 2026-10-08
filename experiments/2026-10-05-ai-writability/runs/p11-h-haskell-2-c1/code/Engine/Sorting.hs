-- | Ordering and equality of rows of values: ORDER BY (SPEC 1.7), DISTINCT and GROUP BY keys (SPEC 3.3, 3.4).
module Engine.Sorting
  ( compareByTerms
  , ValueKey
  , valueKey
  , rowKey
  , distinctOn
  ) where

import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Engine.Ast (NullsPos(..), OrderTerm(..))
import Engine.Value

-- | Compare two rows of sort-key values term by term, each term under its own collation (SPEC 7.4);
-- NULLs sort first under ASC and last under DESC unless NULLS FIRST / LAST says otherwise.
compareByTerms :: [(OrderTerm, Collation)] -> [Value] -> [Value] -> Ordering
compareByTerms terms ka kb = mconcat (zipWith3 cmp terms ka kb)
  where
    cmp (term, coll) a b = case (isNull a, isNull b) of
      (True, True) -> EQ
      (True, False) -> if nullsFirst then LT else GT
      (False, True) -> if nullsFirst then GT else LT
      _ -> (if otDesc term then flip else id) (compareValuesC coll) a b
      where nullsFirst = fromMaybe (if otDesc term then NullsLast else NullsFirst) (otNulls term) == NullsFirst

-- | A value that is equal to another when 'compareValuesC' under its collation says so (NULL equals NULL),
-- so it can key a Set or Map. Keys compared with each other are made with the same collation.
data ValueKey = ValueKey Collation Value

valueKey :: Collation -> Value -> ValueKey
valueKey = ValueKey

-- | The key of a row of values, each under the collation of its column.
rowKey :: [Collation] -> [Value] -> [ValueKey]
rowKey = zipWith ValueKey

instance Eq ValueKey where
  a == b = compare a b == EQ

instance Ord ValueKey where
  compare (ValueKey c a) (ValueKey _ b) = compareValuesC c a b

-- | Keep the first element for each key, in the original order.
distinctOn :: Ord k => (a -> k) -> [a] -> [a]
distinctOn key = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | k `Set.member` seen = go seen xs
      | otherwise = x : go (Set.insert k seen) xs
      where k = key x
