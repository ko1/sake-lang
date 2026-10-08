-- | Planning and execution of SELECT (SPEC 1.7, 3.3, 4).
--
-- A SELECT is planned once: every name error and every subquery's shape is
-- reported before a row is read. The resulting 'Plan' is then run, possibly
-- many times, for a correlated subquery, against the rows of the enclosing queries.
module Engine.Select
  ( executeSelect
  , subqueryCompiler
  ) where

import Control.Exception (throw)
import Control.Monad (when)
import Data.List (findIndex, groupBy, intercalate, nub, sortBy, sortOn)
import Data.Maybe (fromMaybe, isJust, maybeToList)
import Engine.Aggregate (aggregateCalls)
import Engine.Catalog
import Engine.Compile
import Engine.Error
import Engine.From
import Engine.Grouping
import Engine.Sorting (compareKeys)
import Engine.Syntax
import Engine.Value

-- | How an ORDER BY term gets its value for a row.
data SortKey
  = ByResult Int -- ^ the n-th (0-based) result column
  | ByExpr RowFn

-- | A planned SELECT: its result columns and a way to run it.
data Plan = Plan
  { planColumns :: [ScopeColumn]
  , planRun :: Env -> Result [[Value]] -- ^ given the rows of the enclosing queries
  }

-- | Run a top-level SELECT, returning the printed lines.
executeSelect :: Database -> SelectStmt -> Result [String]
executeSelect db s = do
  plan <- planSelect db Nothing s
  rows <- planRun plan []
  Right (map (intercalate "|" . map textForm) rows)

-- | How subqueries inside expressions are compiled (SPEC 4.3). A failure
-- while a subquery runs (only an integer overflow) cannot travel through
-- the pure row functions, so it is thrown as 'SqlFailure' and caught by "Engine.Exec".
subqueryCompiler :: Database -> SubqueryCompiler
subqueryCompiler db parent sel = do
  plan <- planSelect db (Just parent) sel
  Right Subquery
    { subWidth = length (planColumns plan)
    , subAffinity = case planColumns plan of
        c : _ -> scAffinity c
        [] -> Nothing
    , subRows = \env -> either (throw . SqlFailure) id (planRun plan env)
    }

-- | A subquery in FROM runs once, with nothing around it.
derivedTable :: Database -> Derived
derivedTable db sel = do
  plan <- planSelect db Nothing sel
  rows <- planRun plan []
  Right (planColumns plan, rows)

-- | Plan a SELECT written inside the (optional) enclosing scope.
planSelect :: Database -> Maybe Scope -> SelectStmt -> Result Plan
planSelect db parent s = do
  (sources, fromRows) <- buildFrom db (derivedTable db) compile parent (selFrom s)
  items <- concat <$> mapM (expandColumn sources) (selColumns s)
  let columns = concatMap sourceColumns sources
      baseScope = newScope compile parent sources
      aliasScope = baseScope {scopeAliases = [(a, e) | (e, Just a) <- items]}
      terms = selOrderBy s
      calls = nub (concatMap aggregateCalls (map fst items ++ maybeToList (selHaving s) ++ [e | OrderTerm e _ _ <- terms]))
      isAggregate = not (null (selGroupBy s)) || any (not . null . aggregateCalls . fst) items
  whereFn <- traverse (fmap snd . compileExpr aliasScope) (selWhere s)
  when (not isAggregate && isJust (selHaving s)) (Left havingNonAggregate)
  -- The rows result columns, HAVING and ORDER BY are evaluated on, and the scope for their names.
  (present, scope) <-
    if isAggregate
      then do
        keyFns <- mapM (compileGroupTerm aliasScope items) (zip [1 ..] (selGroupBy s))
        aggPlans <- mapM (planAggregate baseScope) calls
        let width = length columns
            slotScope = aliasScope {scopeAggs = AggregateSlots (zip calls [width ..])}
        havingFn <- traverse (fmap snd . compileExpr slotScope) (selHaving s)
        let groupsOf outer kept = do
              groups <- mapM (presentGroup outer width aggPlans) (groupRows outer keyFns kept)
              Right [g | g <- groups, maybe True (\f -> truthValue (f (g : outer)) == Just True) havingFn]
        Right (groupsOf, slotScope)
      else Right (\_ kept -> Right kept, aliasScope {scopeAggs = NoAggregates misuseOfAggregateAlias misuseOfAggregateAlias})
  compiled <- mapM (compileExpr scope . fst) items
  let resultFns = map snd compiled
  keys <- mapM (compileOrderTerm scope items) (zip [1 ..] terms)
  limit <- traverse compileCount (selLimit s)
  offset <- traverse compileCount (selOffset s)
  let outColumns = [ ScopeColumn (resultName e a) affinity False
                   | ((e, a), (affinity, _)) <- zip items compiled ]
      run outer = do
        let kept = [ r | r <- fromRows outer
                   , maybe True (\f -> truthValue (f (r : outer)) == Just True) whereFn ]
        sourceRows <- present outer kept
        let evaluated = map (evalRow outer resultFns keys) sourceRows
            distinct = if selDistinct s then dedupe fst evaluated else evaluated
            sorted = map fst (sortBy (\(_, a) (_, b) -> compareKeys terms a b) distinct)
            afterOffset = drop (max 0 (fromMaybe 0 offset)) sorted
        Right $ case limit of
          Just n | n >= 0 -> take n afterOffset
          _ -> afterOffset
  Right (Plan outColumns run)
  where
    compile = subqueryCompiler db
    compileCount e = evalCount . snd <$> compileExpr (rootScope compile) e

-- | The name a result column has when it is a column of a subquery in FROM (SPEC 4.1).
resultName :: Expr -> Maybe Ident -> Ident
resultName _ (Just alias) = alias
resultName (EColumn _ n) Nothing = n
resultName _ Nothing = ""

-- | Keep the first of each run of equal items (by the key's values, NULLs equal), in order.
dedupe :: (a -> [Value]) -> [a] -> [a]
dedupe key xs =
  map (snd . snd) . sortOn (fst . snd) . map (\g -> case g of x : _ -> x; [] -> error "groupBy returns non-empty groups") . groupBy (\a b -> sameKey a b)
    . sortBy (\a b -> cmpKey a b <> compare (fst (snd a)) (fst (snd b)))
    $ [(key x, (i, x)) | (i, x) <- zip [0 :: Int ..] xs]
  where
    cmpKey (a, _) (b, _) = mconcat (zipWith compareValues a b)
    sameKey a b = cmpKey a b == EQ

-- | A GROUP BY term: an ordinal names a result column; anything else is an
-- expression of the source row (names resolve as in 'compileExpr').
compileGroupTerm :: Scope -> [(Expr, Maybe Ident)] -> (Int, Expr) -> Result RowFn
compileGroupTerm sc items (pos, e) = case ordinalOf e of
  Just k
    | k >= 1 && k <= fromIntegral n -> compile (fst (items !! (fromIntegral k - 1)))
    | otherwise -> Left (groupByRange pos n)
  Nothing -> compile e
  where
    n = length items
    compile x = snd <$> compileExpr sc {scopeAggs = NoAggregates groupByAggregate groupByAggregate} x

-- | A source row's result values and its sort-key values.
evalRow :: Env -> [RowFn] -> [SortKey] -> Row -> ([Value], [Value])
evalRow outer resultFns keys r = (results, map keyValue keys)
  where
    env = r : outer
    results = map ($ env) resultFns
    keyValue (ByResult i) = results !! i
    keyValue (ByExpr f) = f env

-- | A result column as (expression, alias); @*@ and @q.*@ become column references.
expandColumn :: [Source] -> ResultCol -> Result [(Expr, Maybe Ident)]
expandColumn _ (ResultExpr e a) = Right [(e, a)]
expandColumn sources Star = expandStar sources Nothing
expandColumn sources (TableStar q) = expandStar sources (Just q)

compileOrderTerm :: Scope -> [(Expr, Maybe Ident)] -> (Int, OrderTerm) -> Result SortKey
compileOrderTerm sc items (pos, OrderTerm e _ _) = case ordinalOf e of
  Just k
    | k >= 1 && k <= fromIntegral n -> Right (ByResult (fromIntegral k - 1))
    | otherwise -> Left (orderByRange pos n)
  Nothing -> case e of
    EColumn Nothing name
      | Just i <- findIndex (\(_, a) -> fmap identKey a == Just (identKey name)) items -> Right (ByResult i)
    _ -> ByExpr . snd <$> compileExpr sc e
  where
    n = length items

-- | The k of an integer literal @k@ or @-k@ used as an ORDER BY term.
ordinalOf :: Expr -> Maybe Integer
ordinalOf (ELit (VInt k)) = Just (fromIntegral k)
ordinalOf (EUnary Neg (ELit (VInt k))) = Just (negate (fromIntegral k))
ordinalOf _ = Nothing

-- | Evaluate a LIMIT/OFFSET expression (no row in scope) to a count.
evalCount :: RowFn -> Int
evalCount f = case f [[]] of
  VInt i -> fromIntegral i
  VReal d -> truncate d
  VText t -> case numericPrefix t of
    VInt i -> fromIntegral i
    VReal d -> truncate d
    _ -> 0
  VNull -> 0
