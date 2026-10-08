-- | The queue algorithm of a recursive cte (SPEC 5.2).
module Engine.Recursive
  ( recursiveRows
  ) where

import qualified Data.Sequence as Seq
import Data.Sequence (Seq, ViewL(..), viewl, (|>))
import qualified Data.Set as Set
import Engine.Sorting (ValueKey, rowKey)
import Engine.Value (Collation, Value)

-- | @recursiveRows distinct initial step@: the rows of the cte in the order they leave the queue.
-- Each row taken from the queue is added to the result and @step@ (the recursive select with the cte
-- standing for that row) puts its rows at the end. With @distinct@ (UNION), a row equal to one that
-- was ever queued is not queued again, rows being compared under the columns' collations.
recursiveRows :: [Collation] -> Bool -> [[Value]] -> ([Value] -> Either String [[Value]]) -> Either String [[Value]]
recursiveRows colls distinct initial step = go (Seq.fromList queued0) seen0 []
  where
    (queued0, seen0) = enqueue Set.empty initial
    go :: Seq [Value] -> Set.Set [ValueKey] -> [[Value]] -> Either String [[Value]]
    go queue seen acc = case viewl queue of
      EmptyL -> Right (reverse acc)
      row :< rest -> do
        produced <- step row
        let (fresh, seen') = enqueue seen produced
        go (foldl (|>) rest fresh) seen' (row : acc)
    -- the rows to queue (dropping repeats under UNION) and the updated set of rows seen
    enqueue seen rows
      | distinct = let (kept, seen') = foldl admit ([], seen) rows in (reverse kept, seen')
      | otherwise = (rows, seen)
    admit (kept, seen) row
      | key `Set.member` seen = (kept, seen)
      | otherwise = (row : kept, Set.insert key seen)
      where key = rowKey colls row
