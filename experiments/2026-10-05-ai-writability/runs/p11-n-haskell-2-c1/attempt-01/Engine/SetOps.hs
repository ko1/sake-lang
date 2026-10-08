-- | The set operators on lists of rows (SPEC 5.1). Rows are equal as in SELECT DISTINCT (3.4).
module Engine.SetOps
  ( combine
  , opName
  ) where

import qualified Data.Set as Set
import Engine.Ast (SetOp(..))
import Engine.Sorting (distinctOn, rowKey)
import Engine.Value (Collation, Value)

-- | The operator as written, for error messages.
opName :: SetOp -> String
opName Union = "UNION"
opName UnionAll = "UNION ALL"
opName Intersect = "INTERSECT"
opName Except = "EXCEPT"

-- | @combine colls op left right@: rows are equal when equal under the columns' collations @colls@ (SPEC 7.4).
-- Every operator but UNION ALL keeps one of each distinct row, first occurrence first.
combine :: [Collation] -> SetOp -> [[Value]] -> [[Value]] -> [[Value]]
combine _ UnionAll l r = l ++ r
combine colls Union l r = distinct colls (l ++ r)
combine colls Intersect l r = distinct colls (filter (inRight colls r) l)
combine colls Except l r = distinct colls (filter (not . inRight colls r) l)

distinct :: [Collation] -> [[Value]] -> [[Value]]
distinct colls = distinctOn (rowKey colls)

-- | Is the row among the rows of the right side? (@inRight colls r@ builds the set once per partial application.)
inRight :: [Collation] -> [[Value]] -> [Value] -> Bool
inRight colls rows = \row -> rowKey colls row `Set.member` keys
  where keys = Set.fromList (map (rowKey colls) rows)
