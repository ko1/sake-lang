-- | The set operators on lists of rows (SPEC 5.1). Rows are equal as in SELECT DISTINCT (3.4).
module Engine.SetOps
  ( combine
  , opName
  ) where

import qualified Data.Set as Set
import Engine.Ast (SetOp(..))
import Engine.Sorting (ValueKey(..), distinctOn)
import Engine.Value (Value)

-- | The operator as written, for error messages.
opName :: SetOp -> String
opName Union = "UNION"
opName UnionAll = "UNION ALL"
opName Intersect = "INTERSECT"
opName Except = "EXCEPT"

-- | @combine op left right@. Every operator but UNION ALL keeps one of each distinct row, first occurrence first.
combine :: SetOp -> [[Value]] -> [[Value]] -> [[Value]]
combine UnionAll l r = l ++ r
combine Union l r = distinct (l ++ r)
combine Intersect l r = distinct (filter (inRight r) l)
combine Except l r = distinct (filter (not . inRight r) l)

distinct :: [[Value]] -> [[Value]]
distinct = distinctOn rowKey

-- | Is the row among the rows of the right side? (@inRight r@ builds the set once per partial application.)
inRight :: [[Value]] -> [Value] -> Bool
inRight rows = \row -> rowKey row `Set.member` keys
  where keys = Set.fromList (map rowKey rows)

rowKey :: [Value] -> [ValueKey]
rowKey = map ValueKey
