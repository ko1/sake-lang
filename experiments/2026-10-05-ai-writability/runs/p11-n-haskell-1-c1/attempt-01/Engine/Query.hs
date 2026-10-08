-- | Full queries: WITH tables (recursive ones included) and compound selects
-- (SPEC 5.1, 5.2). Each simple select is planned by "Engine.Select".
module Engine.Query
  ( queryCompiler
  , queryResult
  , executeQuery
  ) where

import Control.Monad (foldM, unless, zipWithM)
import Data.List (findIndex, intercalate, sortBy)
import Data.Maybe (fromMaybe, listToMaybe)
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
executeQuery db query = map (intercalate "|" . map textForm) . snd <$> queryResult db query

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
      colls = columnCollations columns
      admit seen row
        | op == UnionAll = (True, seen)
        | RowKey colls row `Set.member` seen = (False, seen)
        | otherwise = (True, Set.insert (RowKey colls row) seen)
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
  let columnSets = map planColumns (firstPlan : map snd parts)
      -- the k-th column has the collation of the first select whose k-th column has one (SPEC 7.4)
      infos = [ listToMaybe [i | cols <- columnSets, Just i <- [scCollation (cols !! k)]] | k <- [0 .. width - 1] ]
      colls = map (maybe Binary infoCollation) infos
      outColumns = zipWith (\c info -> c {scCollation = info}) (planColumns firstPlan) infos
  keyed <- zipWithM (orderColumn colls (map planColumns (firstPlan : map snd parts))) [1 ..] order
  let keys = map fst keyed
      keyColls = map snd keyed
  limitN <- traverse (compileCount ctx) limit
  offsetN <- traverse (compileCount ctx) offset
  let run outer = do
        firstRows <- planRun firstPlan outer
        rows <- foldM (\acc (op, p) -> combine colls op acc <$> planRun p outer) firstRows parts
        let sorted = sortBy (\a b -> compareKeys order keyColls (map (a !!) keys) (map (b !!) keys)) rows
            afterOffset = drop (max 0 (fromMaybe 0 offsetN)) sorted
        Right $ case limitN of
          Just n | n >= 0 -> take n afterOffset
          _ -> afterOffset
  Right (Plan outColumns run)

opName :: SetOp -> String
opName UnionAll = "UNION ALL"
opName Union = "UNION"
opName Intersect = "INTERSECT"
opName Except = "EXCEPT"

-- | Left operand rows combined with the right operand's (SPEC 5.1).
-- Rows are equal when equal under the columns' collations @colls@.
combine :: [Collation] -> SetOp -> [[Value]] -> [[Value]] -> [[Value]]
combine _ UnionAll l r = l ++ r
combine colls Union l r = dedupeBy colls id (l ++ r)
combine colls Intersect l r = dedupeBy colls id [x | x <- l, RowKey colls x `Set.member` keysOf colls r]
combine colls Except l r = dedupeBy colls id [x | x <- l, not (RowKey colls x `Set.member` keysOf colls r)]

keysOf :: [Collation] -> [[Value]] -> Set.Set RowKey
keysOf colls = Set.fromList . map (RowKey colls)

-- | The collations rows of these columns compare under.
columnCollations :: [ScopeColumn] -> [Collation]
columnCollations = map (maybe Binary infoCollation . scCollation)

-- | The result column an ORDER BY term of a compound select names: a column
-- number, or a name looked for in the result columns of each select in turn.
-- Also the collation it sorts under: its own @COLLATE@, else the column's (@colls@).
orderColumn :: [Collation] -> [[ScopeColumn]] -> Int -> OrderTerm -> Result (Int, Collation)
orderColumn colls columnSets pos (OrderTerm term _ _) = do
  (e, written) <- case term of
    ECollate inner name -> case collationByName name of
      Just c -> Right (inner, Just c)
      Nothing -> Left (noSuchCollation name)
    _ -> Right (term, Nothing)
  i <- case e of
    ELit (VInt k) -> ordinal (fromIntegral k)
    EUnary Neg (ELit (VInt k)) -> ordinal (negate (fromIntegral k))
    EColumn Nothing name
      | (i : _) <- [i | cols <- columnSets, Just i <- [findIndex ((== identKey name) . identKey . scName) cols]] -> Right i
    _ -> Left (orderByNoMatch pos)
  Right (i, fromMaybe (colls !! i) written)
  where
    width = length colls
    ordinal k
      | k >= 1 && k <= width = Right (k - 1)
      | otherwise = Left (orderByRange pos width)
