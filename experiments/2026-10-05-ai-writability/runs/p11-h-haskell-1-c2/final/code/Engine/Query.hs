-- | Full queries: WITH tables (recursive ones included) and compound selects
-- (SPEC 5.1, 5.2). Each simple select is planned by "Engine.Select".
module Engine.Query
  ( queryCompiler
  , queryResult
  , executeQuery
  ) where

import Control.Monad (foldM, unless, zipWithM)
import Data.List (findIndex, intercalate, sortBy)
import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Data.Sequence (Seq (..), (><))
import qualified Data.Sequence as Seq
import Engine.Catalog (Database)
import Engine.Error
import Engine.Plan
import Engine.Scope
import Engine.Select
import Engine.Sorting (RowKey (..), compareKeys, dedupeBy)
import Engine.Syntax
import Engine.Value

-- | How the subqueries of a statement that has no query around it (INSERT values, UPDATE) are compiled.
queryCompiler :: Database -> SubqueryCompiler
queryCompiler = subqueryCompiler . rootCtx

rootCtx :: Database -> Ctx
rootCtx db = Ctx db [] planQuery

-- | Run a query: the number of its result columns and its rows.
queryResult :: Database -> Query -> Result (Int, [[Value]])
queryResult db query = do
  plan <- planQuery (rootCtx db) Nothing query
  rows <- planRun plan []
  Right (length (planColumns plan), rows)

-- | Run a top-level SELECT, returning the printed lines.
executeQuery :: Database -> Query -> Result [String]
executeQuery db query = map (intercalate "|" . map printForm) . snd <$> queryResult db query

planQuery :: Ctx -> Maybe Scope -> Query -> Result Plan
planQuery ctx parent (Query with body) = do
  ctx' <- maybe (Right ctx) (addCtes ctx) with
  planBody ctx' parent body

-- WITH ------------------------------------------------------------------

-- | Bring the WITH tables into scope, each visible to the ones after it.
addCtes :: Ctx -> With -> Result Ctx
addCtes ctx (With isRecursive ctes) = do
  checkDistinct [] [n | Cte n _ _ <- ctes]
  Right (foldl add ctx ctes)
  where
    add c (Cte name columns query) = c {ctxCtes = (identKey name, source c) : ctxCtes c}
      where
        source before = case recursiveParts name query of
          Just parts | isRecursive -> recursiveCte before name columns parts
          _ -> do
            plan <- planIn before Nothing query
            rows <- planRun plan []
            Right (withColumnNames columns (planColumns plan), rows)
    checkDistinct _ [] = Right ()
    checkDistinct seen (n : rest)
      | identKey n `elem` seen = Left (duplicateCte n)
      | otherwise = checkDistinct (identKey n : seen) rest

-- | A recursive cte's select split into the initial part, the operator and the recursive part.
data RecursiveParts = RecursiveParts Query SetOp SelectStmt

-- | A cte is recursive when its select is a UNION / UNION ALL whose last part mentions its name.
recursiveParts :: Ident -> Query -> Maybe RecursiveParts
recursiveParts name (Query Nothing (Compound first rest _))
  | (op, recursive) <- last rest, op `elem` [Union, UnionAll], mentions recursive =
      Just (RecursiveParts (Query Nothing initial) op recursive)
  where
    initial = case init rest of
      [] -> Plain first
      before -> Compound first before (CompoundTail [] Nothing Nothing)
    mentions sel = case selFrom sel of
      Nothing -> False
      Just (FromClause item joins) -> any named (item : [i | Join _ i _ <- joins])
    named (FromTable n _) = identKey n == identKey name
    named _ = False
recursiveParts _ _ = Nothing

-- | The queue algorithm of SPEC 5.2: the recursive part is planned afresh for
-- each row taken from the queue, with the cte standing for that row.
recursiveCte :: Ctx -> Ident -> Maybe [Ident] -> RecursiveParts -> Named
recursiveCte ctx name columnNames (RecursiveParts initialQuery op recursive) = do
  initialPlan <- planIn ctx Nothing initialQuery
  let columns = withColumnNames columnNames (planColumns initialPlan)
      planStep rows = planSelect ctx {ctxCtes = (identKey name, Right (columns, rows)) : ctxCtes ctx} Nothing recursive
      admit seen row
        | op == UnionAll = (True, seen)
        | RowKey row `Set.member` seen = (False, seen)
        | otherwise = (True, Set.insert (RowKey row) seen)
      admitAll seen = foldl' (\(kept, s) row -> let (ok, s') = admit s row in (if ok then row : kept else kept, s')) ([], seen)
      loop _ Empty done = Right (reverse done)
      loop seen (row :<| queue) done = do
        plan <- planStep [row]
        new <- planRun plan []
        let (fresh, seen') = admitAll seen new
        loop seen' (queue >< Seq.fromList (reverse fresh)) (row : done)
  _ <- planStep [] -- report the recursive part's errors even if the initial part is empty
  initialRows <- planRun initialPlan []
  let (fresh0, seen0) = admitAll Set.empty initialRows
  rows <- loop seen0 (Seq.fromList (reverse fresh0)) []
  Right (columns, rows)

-- Compound selects ------------------------------------------------------

planBody :: Ctx -> Maybe Scope -> QueryBody -> Result Plan
planBody ctx parent (Plain sel) = planSelect ctx parent sel
planBody ctx parent (Compound first rest (CompoundTail order limit offset)) = do
  firstPlan <- planSelect ctx parent first
  let width = length (planColumns firstPlan)
  parts <- mapM (\(op, sel) -> (,) op <$> planSelect ctx parent sel) rest
  mapM_ (\(op, p) -> unless (length (planColumns p) == width) (Left (compoundMismatch (opName op)))) parts
  keys <- zipWithM (orderColumn width (map planColumns (firstPlan : map snd parts))) [1 ..] order
  limitN <- traverse (compileCount ctx) limit
  offsetN <- traverse (compileCount ctx) offset
  let run outer = do
        firstRows <- planRun firstPlan outer
        rows <- foldM (\acc (op, p) -> combine op acc <$> planRun p outer) firstRows parts
        let sorted = sortBy (\a b -> compareKeys order (map (a !!) keys) (map (b !!) keys)) rows
            afterOffset = drop (max 0 (fromMaybe 0 offsetN)) sorted
        Right $ case limitN of
          Just n | n >= 0 -> take n afterOffset
          _ -> afterOffset
  Right (Plan (planColumns firstPlan) run)

opName :: SetOp -> String
opName UnionAll = "UNION ALL"
opName Union = "UNION"
opName Intersect = "INTERSECT"
opName Except = "EXCEPT"

-- | Left operand rows combined with the right operand's (SPEC 5.1).
combine :: SetOp -> [[Value]] -> [[Value]] -> [[Value]]
combine UnionAll l r = l ++ r
combine Union l r = dedupeBy id (l ++ r)
combine Intersect l r = dedupeBy id [x | x <- l, RowKey x `Set.member` keysOf r]
combine Except l r = dedupeBy id [x | x <- l, not (RowKey x `Set.member` keysOf r)]

keysOf :: [[Value]] -> Set.Set RowKey
keysOf = Set.fromList . map RowKey

-- | The result column an ORDER BY term of a compound select names: a column
-- number, or a name looked for in the result columns of each select in turn.
orderColumn :: Int -> [[ScopeColumn]] -> Int -> OrderTerm -> Result Int
orderColumn width columnSets pos (OrderTerm e _ _) = case e of
  ELit (VInt k) -> ordinal (fromIntegral k)
  EUnary Neg (ELit (VInt k)) -> ordinal (negate (fromIntegral k))
  EColumn Nothing name
    | (i : _) <- [i | cols <- columnSets, Just i <- [findIndex ((== identKey name) . identKey . scName) cols]] -> Right i
  _ -> Left (orderByNoMatch pos)
  where
    ordinal k
      | k >= 1 && k <= width = Right (k - 1)
      | otherwise = Left (orderByRange pos width)
