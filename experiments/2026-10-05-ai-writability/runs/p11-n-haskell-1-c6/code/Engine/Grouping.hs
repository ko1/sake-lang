-- | Aggregate queries (SPEC 3.3): compiling aggregate calls, partitioning
-- rows into groups, and building the row each group presents to the
-- result columns, HAVING and ORDER BY.
--
-- A group's presented row is its representative source row followed by one
-- value per aggregate call; "Engine.Compile" turns each call into a read of
-- its slot (see 'AggregateSlots').
module Engine.Grouping
  ( AggPlan
  , planAggregate
  , groupRows
  , presentGroup
  ) where

import Data.List (sortBy)
import Data.Maybe (fromMaybe)
import Engine.Aggregate
import Engine.Catalog (Row)
import Engine.Compile
import Engine.Error
import Engine.Sorting (compareKeys, groupOn)
import Engine.Syntax
import Engine.Value

-- | A compiled aggregate call, run over the rows of one group.
data AggPlan = AggPlan
  { planValue :: Env -> [Row] -> Result Value
  , planPick :: Maybe (Env -> [Row] -> Maybe Row) -- ^ min/max: the row that gave the result
  }

-- | Compile one aggregate call (an expression accepted by 'asAggregate').
-- Its arguments and ORDER BY terms are plain expressions of the source row
-- (the 'Env' is that of the enclosing queries).
planAggregate :: Scope -> Expr -> Result AggPlan
planAggregate sc e = case asAggregate e of
  Nothing -> Left (noSuchFunction "aggregate")
  Just call -> do
    impl <- resolveAggregate call
    args <- mapM (fmap snd . compileExpr sc) (acArgs call)
    keys <- mapM (\(OrderTerm x _ _) -> snd <$> compileExpr sc x) (acOrder call)
    let ordered outer rows
          | null keys = rows
          | otherwise =
              map snd . sortBy (\(a, _) (b, _) -> compareKeys (acOrder call) a b) $
                [(map ($ (r : outer)) keys, r) | r <- rows]
        argValues outer rows = [map ($ (r : outer)) args | r <- ordered outer rows]
        pick want outer rows = case [(f (r : outer), r) | r <- rows, let f = head' args, f (r : outer) /= VNull] of
          [] -> Nothing
          (v, r) : more -> Just (snd (foldl (\(bv, br) (x, xr) -> if compareValues x bv == want then (x, xr) else (bv, br)) (v, r) more))
        head' fs = case fs of f : _ -> f; [] -> const VNull
    Right (AggPlan (\outer -> aggFold impl . argValues outer) (fmap pick (aggExtreme impl)))

-- | Partition rows by the GROUP BY key values (NULLs equal), groups in key
-- order and rows in input order. Without keys all rows are one group, even none.
groupRows :: Env -> [RowFn] -> [Row] -> [[Row]]
groupRows _ [] rows = [rows]
groupRows outer keys rows =
  map (map snd) (groupOn fst [(map ($ (r : outer)) keys, r) | r <- rows])

-- | The row a group presents. @width@ is the number of source columns, for
-- the all-NULL representative of the empty group.
presentGroup :: Env -> Int -> [AggPlan] -> [Row] -> Result Row
presentGroup outer width plans rows = do
  values <- mapM (\p -> planValue p outer rows) plans
  Right (representative ++ values)
  where
    representative = case rows of
      [] -> replicate width VNull
      first : _ -> case plans of
        [AggPlan _ (Just pick)] -> fromMaybe first (pick outer rows)
        _ -> first
