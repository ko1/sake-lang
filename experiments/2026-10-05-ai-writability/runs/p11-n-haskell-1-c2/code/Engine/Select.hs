-- | Planning and execution of a simple SELECT (SPEC 1.7, 3.3, 4); compound
-- selects and WITH are "Engine.Query".
--
-- A SELECT is planned once: every name error and every subquery's shape is
-- reported before a row is read. The resulting 'Plan' is then run, possibly
-- many times, for a correlated subquery, against the rows of the enclosing queries.
module Engine.Select
  ( planSelect
  , subqueryCompiler
  , compileCount
  ) where

import Control.Exception (throw)
import Control.Monad (when)
import Data.Foldable (toList)
import Data.List (findIndex, nub, sortBy)
import Data.Maybe (fromMaybe, isJust, maybeToList)
import Engine.Aggregate (aggregateCalls)
import Engine.Catalog
import Engine.Compile
import Engine.Error
import Engine.From
import Engine.Grouping
import Engine.Plan
import Engine.Sorting (compareKeys, dedupeBy)
import Engine.Window (windowCalls)
import Engine.WindowPlan (planWindows)
import Engine.Syntax
import Engine.Value

-- | How an ORDER BY term gets its value for a row.
data SortKey
  = ByResult Int -- ^ the n-th (0-based) result column
  | ByExpr RowFn

-- | How subqueries inside expressions are compiled (SPEC 4.3). A failure
-- while a subquery runs (only an integer overflow) cannot travel through
-- the pure row functions, so it is thrown as 'SqlFailure' and caught by "Engine.Exec".
subqueryCompiler :: Ctx -> SubqueryCompiler
subqueryCompiler ctx parent query = do
  plan <- planIn ctx (Just parent) query
  Right Subquery
    { subWidth = length (planColumns plan)
    , subAffinity = case planColumns plan of
        c : _ -> scAffinity c
        [] -> Nothing
    , subRows = \env -> either (throw . SqlFailure) id (planRun plan env)
    }

-- | A subquery in FROM runs once, with nothing around it.
derivedTable :: Ctx -> Derived
derivedTable ctx query = do
  plan <- planIn ctx Nothing query
  rows <- planRun plan []
  Right (planColumns plan, rows)

-- | A name in FROM: a WITH table (hides the others), a view, or a table (SPEC 5.2, 5.3).
namedSource :: Ctx -> Ident -> Result ([ScopeColumn], [Row])
namedSource ctx name = case lookup (identKey name) (ctxCtes ctx) of
  Just source -> source
  Nothing -> case findView name db of
    Just view -> do
      plan <- planIn ctx {ctxCtes = []} Nothing (viewQuery view)
      rows <- planRun plan []
      Right (withColumnNames (viewColumns view) (planColumns plan), rows)
    Nothing -> do
      table <- findTable name db `orElse` noSuchTable name
      Right ( [ScopeColumn (columnName c) (Just (columnType c)) False | c <- tableColumns table]
            , toList (tableRows table) )
  where
    db = ctxDb ctx

-- | Plan a SELECT written inside the (optional) enclosing scope.
planSelect :: Ctx -> Maybe Scope -> SelectStmt -> Result Plan
planSelect ctx parent s = do
  (sources, fromRows) <- buildFrom (namedSource ctx) (derivedTable ctx) compile parent (selFrom s)
  items <- concat <$> mapM (expandColumn sources) (selColumns s)
  let columns = concatMap sourceColumns sources
      baseScope = newScope compile parent sources
      aliasScope = baseScope {scopeAliases = [(a, e) | (e, Just a) <- items]}
      terms = selOrderBy s
      calls = nub (concatMap aggregateCalls (map fst items ++ maybeToList (selHaving s) ++ [e | OrderTerm e _ _ <- terms]))
      slotCount = if isAggregate then length calls else 0
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
  (windowSlots, addWindows) <-
    planWindows scope (selWindows s) (length columns + slotCount) (concatMap windowCalls (map fst items ++ [e | OrderTerm e _ _ <- terms]))
  let scope' = scope {scopeWindows = windowSlots}
  compiled <- mapM (compileExpr scope' . fst) items
  let resultFns = map snd compiled
  keys <- mapM (compileOrderTerm scope' items) (zip [1 ..] terms)
  limit <- traverse compileCount' (selLimit s)
  offset <- traverse compileCount' (selOffset s)
  let outColumns = [ ScopeColumn (resultName e a) affinity False
                   | ((e, a), (affinity, _)) <- zip items compiled ]
      run outer = do
        let kept = [ r | r <- fromRows outer
                   , maybe True (\f -> truthValue (f (r : outer)) == Just True) whereFn ]
        sourceRows <- present outer kept >>= addWindows outer
        let evaluated = map (evalRow outer resultFns keys) sourceRows
            distinct = if selDistinct s then dedupeBy fst evaluated else evaluated
            sorted = map fst (sortBy (\(_, a) (_, b) -> compareKeys terms a b) distinct)
            afterOffset = drop (max 0 (fromMaybe 0 offset)) sorted
        Right $ case limit of
          Just n | n >= 0 -> take n afterOffset
          _ -> afterOffset
  Right (Plan outColumns run)
  where
    compile = subqueryCompiler ctx
    compileCount' = compileCount ctx

-- | The name a result column has when it is a column of a subquery in FROM (SPEC 4.1).
resultName :: Expr -> Maybe Ident -> Ident
resultName _ (Just alias) = alias
resultName (EColumn _ n) Nothing = n
resultName _ Nothing = ""

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
  VText t -> evalCount (const (numericPrefix t))
  VBlob t -> evalCount (const (numericPrefix t))
  VNull -> 0

-- | A LIMIT/OFFSET expression, compiled with no row in scope.
compileCount :: Ctx -> Expr -> Result Int
compileCount ctx e = evalCount . snd <$> compileExpr (rootScope (subqueryCompiler ctx)) e
