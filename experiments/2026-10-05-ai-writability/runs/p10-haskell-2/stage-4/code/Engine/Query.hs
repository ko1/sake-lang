-- | SELECT (SPEC 1.7, 3.3, 3.4, 4): a statement is compiled once (names resolved, every name error
-- raised before any row is read) into a function from the rows of the enclosing queries to its rows.
module Engine.Query
  ( runSelect
  , selectBinder
  ) where

import Control.Monad (when)
import Control.Monad.State.Strict (StateT, runStateT)
import Data.List (sortBy)
import qualified Data.Map.Strict as Map
import Data.Maybe (isJust)
import Engine.Aggregate
import Engine.Ast
import Engine.Catalog
import Engine.Coerce (toNumber, truthOf)
import Engine.Expr
import Engine.From
import Engine.Names (foldName)
import Engine.Scope
import Engine.Sorting
import Engine.Value

-- | Where an ORDER BY term takes its value from.
data SortKey = FromResult Int | FromRow Bound

-- | A result column: its name for outer queries (alias, else a plain column's name), its alias, its expression.
data ResultItem = ResultItem
  { riLabel :: String
  , riAlias :: Maybe String
  , riExpr :: Expr
  }

-- | A compiled SELECT, ready to run.
data Plan = Plan
  { plFrom :: FromPlan
  , plColumns :: [ScopeColumn]      -- the result columns, as an outer query sees them
  , plWidth :: Int                  -- columns of a FROM row
  , plWhere :: Maybe Bound
  , plGroupKeys :: [Bound]
  , plAggregates :: Maybe [AggSpec] -- Just: an aggregate query, with the calls it needs
  , plHaving :: Maybe Bound
  , plResults :: [Bound]
  , plKeys :: [SortKey]
  , plOrder :: [OrderTerm]
  , plDistinct :: Bool
  , plLimit :: Maybe Bound
  , plOffset :: Maybe Bound
  }

-- | Rows of a top-level SELECT, as values.
runSelect :: Database -> Select -> Either String [[Value]]
runSelect db sel = selectBinder db Nothing sel >>= \sq -> sqRun sq []

-- | How a SELECT inside an expression or a FROM is compiled, given the scope enclosing it.
selectBinder :: Database -> SelectBinder
selectBinder db outer sel = (\plan -> Subquery (plColumns plan) (runPlan plan)) <$> planSelect db outer sel

-- | Resolve everything in the SELECT.
planSelect :: Database -> Maybe Scope -> Select -> Either String Plan
planSelect db outer sel = do
  from <- maybe (Right noFrom) (compileFrom db binder outer) (selFrom sel)
  let scope0 = newScope binder outer (fpSources from)
  items <- expandItems scope0 (selItems sel)
  let nResults = length items
      isAggregate = not (null (selGroupBy sel)) || any (isJust . containsAggregate . riExpr) items
  when (not isAggregate && isJust (selHaving sel)) $ Left "HAVING clause on a non-aggregate query"
  -- aggregate calls become slots after the row's columns (identical calls share one)
  ((itemExprs, havingExpr, orderTerms), calls) <-
    if isAggregate
      then runStateT (liftQuery items sel) []
      else Right ((map riExpr items, selHaving sel, selOrderBy sel), [])
  specs <- traverse (bindAggregate scope0) calls
  results <- traverse (bindExpr scope0) itemExprs
  let named = [ (foldName a, (riExpr i, b)) | (i, b) <- zip items results, Just a <- [riAlias i] ]
      aliasesWith f = [ (a, f e b) | (a, (e, b)) <- named ]
      whereScope = scope0 { scopeAliases = aliasesWith $ \e b ->
        maybe (Right b) (\n -> Left ("misuse of aggregate: " ++ n ++ "()")) (containsAggregate e) }
      groupScope = scope0 { scopeAliases = aliasesWith $ \e b ->
        maybe (Right b) (const (Left groupByAggregate)) (containsAggregate e) }
      afterScope = scope0 { scopeAliases = aliasesWith (\_ b -> Right b)
                          , scopeAggMisuse = \n -> "misuse of aggregate: " ++ n ++ "()" }
  cond <- traverse (bindExpr whereScope) (selWhere sel)
  groupKeys <- traverse (uncurry (groupKey groupScope items results)) (zip [1 ..] (selGroupBy sel))
  having <- traverse (bindExpr afterScope) havingExpr
  keys <- traverse (uncurry (sortKey afterScope [ (foldName a, k) | (k, i) <- zip [0 ..] items, Just a <- [riAlias i] ] nResults))
                   (zip [1 ..] orderTerms)
  let constantScope = newScope binder outer []
  lim <- traverse (bindExpr constantScope) (selLimit sel)
  off <- traverse (bindExpr constantScope) (selOffset sel)
  Right Plan
    { plFrom = from
    , plColumns = [ ScopeColumn (riLabel i) (affinityOf b) False | (i, b) <- zip items results ]
    , plWidth = scopeWidth scope0, plWhere = cond, plGroupKeys = groupKeys
    , plAggregates = if isAggregate then Just specs else Nothing
    , plHaving = having, plResults = results, plKeys = keys, plOrder = orderTerms
    , plDistinct = selDistinct sel, plLimit = lim, plOffset = off }
  where binder = selectBinder db

-- | Run a compiled SELECT; @ctx@ holds the rows of the enclosing queries.
--
-- WHERE filters the FROM rows; an aggregate query groups them and turns each group into one row (the
-- group's bare-column row followed by its aggregate values, see 'Engine.Aggregate'); HAVING filters;
-- result columns and ORDER BY keys are computed on these rows; DISTINCT, ORDER BY, LIMIT / OFFSET finish.
runPlan :: Plan -> Env -> Either String [[Value]]
runPlan pl ctx = do
  fromRows <- fpRows (plFrom pl) ctx
  let holds b r = truthOf (evalExpr (r : ctx) b) == Just True
      kept = filter (\r -> maybe True (`holds` r) (plWhere pl)) fromRows
  units <- case plAggregates pl of
    Just specs -> traverse (groupRow ctx (plWidth pl) specs) (groupsOf ctx (plGroupKeys pl) kept)
    Nothing -> Right kept
  let surviving = filter (\r -> maybe True (`holds` r) (plHaving pl)) units
      withKeys = [ (out, [ keyValue ctx out r k | k <- plKeys pl ])
                 | r <- surviving, let out = [ evalExpr (r : ctx) b | b <- plResults pl ] ]
      distinct = if plDistinct pl then distinctOn (map ValueKey . fst) withKeys else withKeys
      sorted = sortBy (\(_, ka) (_, kb) -> compareByTerms (plOrder pl) ka kb) distinct
  Right (limitRows (constantInt ctx <$> plLimit pl) (constantInt ctx <$> plOffset pl) (map fst sorted))

-- | Result columns with '*' and 'q.*' expanded.
expandItems :: Scope -> [SelectItem] -> Either String [ResultItem]
expandItems scope = fmap concat . traverse expand
  where
    sources = scopeSources scope
    offsets = scanl (+) 0 (map sourceWidth sources)
    expand Star
      | null sources = Left "no tables specified"
      | otherwise = Right [ column (off + i) c | (off, s) <- zip offsets sources, (i, c) <- zip [0 ..] (srcColumns s), not (scHidden c) ]
    expand (QualifiedStar q) =
      case [ (off, s) | (off, s) <- zip offsets sources, fmap foldName (srcName s) == Just (foldName q) ] of
        (off, s) : _ -> Right [ column (off + i) c | (i, c) <- zip [0 ..] (srcColumns s) ]
        [] -> Left ("no such table: " ++ q)
    expand (Item e alias) = Right [ResultItem (maybe (plainName e) id alias) alias e]
    column i c = ResultItem (scName c) Nothing (EColumnAt i)
    plainName (EName n) = n
    plainName (EQualified _ n) = n
    plainName _ = ""

-- | Replace the aggregate calls of the result columns, HAVING and ORDER BY by slot references.
liftQuery :: [ResultItem] -> Select -> StateT [AggCall] (Either String) ([Expr], Maybe Expr, [OrderTerm])
liftQuery items sel = do
  es <- traverse (liftAggregates . riExpr) items
  h <- traverse liftAggregates (selHaving sel)
  o <- traverse (\t -> (\e -> t { otExpr = e }) <$> liftAggregates (otExpr t)) (selOrderBy sel)
  pure (es, h, o)

groupByAggregate :: String
groupByAggregate = "aggregate functions are not allowed in the GROUP BY clause"

-- | A GROUP BY term: an integer is a result column's position (SPEC 3.3), anything else an expression.
groupKey :: Scope -> [ResultItem] -> [Bound] -> Int -> Expr -> Either String Bound
groupKey scope items results pos term = case term of
  ELit (VInt k) -> ordinal k
  EUnary Neg (ELit (VInt k)) -> ordinal (negate k)
  e | isJust (containsAggregate e) -> Left groupByAggregate
    | otherwise -> bindExpr scope e
  where
    ordinal k
      | k >= 1 && k <= length results
      , e <- riExpr (items !! (k - 1)) = maybe (Right (results !! (k - 1))) (const (Left groupByAggregate)) (containsAggregate e)
      | otherwise = Left (ordinalName pos ++ " GROUP BY term out of range - should be between 1 and "
                          ++ show (length results))

-- | Rows with equal key values form a group, groups in key order; without GROUP BY one group, even if empty.
groupsOf :: Env -> [Bound] -> [[Value]] -> [[[Value]]]
groupsOf _ [] rows = [rows]
groupsOf ctx keys rows =
  map reverse (Map.elems (Map.fromListWith (++) [ (map (ValueKey . evalExpr (r : ctx)) keys, [r]) | r <- rows ]))

-- | The row a group evaluates on: its bare-column row, then the value of each aggregate.
groupRow :: Env -> Int -> [AggSpec] -> [[Value]] -> Either String [Value]
groupRow ctx width specs rows = (bareColumnRow ctx width specs rows ++) <$> traverse (\spec -> computeAggregate ctx spec rows) specs

sortKey :: Scope -> [(String, Int)] -> Int -> Int -> OrderTerm -> Either String SortKey
sortKey scope aliases nResults pos term = case otExpr term of
  EName n | Just i <- lookup (foldName n) aliases -> Right (FromResult i)
  ELit (VInt k) -> ordinal k
  EUnary Neg (ELit (VInt k)) -> ordinal (negate k)
  e -> FromRow <$> bindExpr scope e
  where
    ordinal k
      | k >= 1 && k <= nResults = Right (FromResult (k - 1))
      | otherwise = Left (ordinalName pos ++ " ORDER BY term out of range - should be between 1 and "
                          ++ show nResults)

-- | 1st, 2nd, 3rd, 4th, ... 11th, 12th, 13th, 21st ...
ordinalName :: Int -> String
ordinalName n = show n ++ suffix
  where
    suffix | n `mod` 100 `elem` [11, 12, 13] = "th"
           | n `mod` 10 == 1 = "st"
           | n `mod` 10 == 2 = "nd"
           | n `mod` 10 == 3 = "rd"
           | otherwise = "th"

keyValue :: Env -> [Value] -> [Value] -> SortKey -> Value
keyValue _ out _ (FromResult i) = out !! i
keyValue ctx _ row (FromRow b) = evalExpr (row : ctx) b

-- | LIMIT / OFFSET expressions have no row in scope.
constantInt :: Env -> Bound -> Int
constantInt ctx b = case toNumber (evalExpr ([] : ctx) b) of
  VInt n -> n
  VReal d -> truncate d
  _ -> 0

-- | A negative LIMIT means no limit; a negative OFFSET counts as 0.
limitRows :: Maybe Int -> Maybe Int -> [a] -> [a]
limitRows lim off rows = maybe id limit lim (drop (maybe 0 (max 0) off) rows)
  where limit n = if n < 0 then id else take n

