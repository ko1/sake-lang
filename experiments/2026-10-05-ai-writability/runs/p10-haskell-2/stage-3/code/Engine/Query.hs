-- | SELECT evaluation (SPEC 1.7, 3.3, 3.4): name resolution, WHERE, grouping, HAVING, DISTINCT, ORDER BY, LIMIT / OFFSET.
module Engine.Query
  ( runSelect
  ) where

import Control.Monad (when)
import Control.Monad.State.Strict (StateT, runStateT)
import Data.Foldable (toList)
import Data.List (sortBy)
import qualified Data.Map.Strict as Map
import Data.Maybe (isJust)
import Engine.Aggregate
import Engine.Ast
import Engine.Catalog
import Engine.Coerce (toNumber, truthOf)
import Engine.Expr
import Engine.Names (foldName)
import Engine.Sorting
import Engine.Value

-- | Where an ORDER BY term takes its value from.
data SortKey = FromResult Int | FromRow Bound

-- | Rows of the result, as values.
--
-- Pipeline: WHERE filters the table's rows; an aggregate query groups them and turns each group
-- into one row (the group's bare-column row followed by its aggregate values, see 'Engine.Aggregate');
-- HAVING filters; result columns and ORDER BY keys are computed on these rows; DISTINCT, ORDER BY,
-- LIMIT / OFFSET finish.
runSelect :: Database -> Select -> Either String [[Value]]
runSelect db sel = do
  tbl <- case selFrom sel of
    Nothing -> Right Nothing
    Just name -> maybe (Left ("no such table: " ++ name)) (Right . Just) (lookupTable name db)
  let cols = maybe [] tableColumns tbl
      sourceRows = maybe [[]] (toList . tableRows) tbl
      scope0 = tableScope cols
  items <- expandItems tbl (selItems sel)
  let nResults = length items
      isAggregate = not (null (selGroupBy sel)) || any (isJust . containsAggregate . snd) items
  when (not isAggregate && isJust (selHaving sel)) $ Left "HAVING clause on a non-aggregate query"
  -- aggregate calls become slots after the row's columns (identical calls share one)
  ((itemExprs, havingExpr, orderTerms), calls) <-
    if isAggregate
      then runStateT (liftQuery items sel) []
      else Right ((map snd items, selHaving sel, selOrderBy sel), [])
  specs <- traverse (bindAggregate scope0) calls
  results <- traverse (bindExpr scope0) itemExprs
  let named = [ (foldName a, (e, b)) | ((Just a, e), b) <- zip items results ]
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
  keys <- traverse (uncurry (sortKey afterScope [ (foldName a, i) | (i, (Just a, _)) <- zip [0 ..] items ] nResults))
                   (zip [1 ..] orderTerms)
  lim <- traverse constantInt (selLimit sel)
  off <- traverse constantInt (selOffset sel)
  let kept = filter (\r -> maybe True (\c -> truthOf (evalExpr r c) == Just True) cond) sourceRows
  units <- if isAggregate
    then traverse (groupRow (length cols) specs) (groupsOf groupKeys kept)
    else Right kept
  let surviving = filter (\r -> maybe True (\h -> truthOf (evalExpr r h) == Just True) having) units
      withKeys = [ (out, [ keyValue out r k | k <- keys ])
                 | r <- surviving, let out = [ evalExpr r b | b <- results ] ]
      distinct = if selDistinct sel then distinctOn (map ValueKey . fst) withKeys else withKeys
      sorted = sortBy (\(_, ka) (_, kb) -> compareByTerms orderTerms ka kb) distinct
  Right (limitRows lim off (map fst sorted))

-- | Result columns with '*' expanded; each is its alias (if written) and expression.
expandItems :: Maybe Table -> [SelectItem] -> Either String [(Maybe String, Expr)]
expandItems tbl = fmap concat . traverse expand
  where
    expand Star = case tbl of
      Nothing -> Left "no tables specified"
      Just t -> Right [ (Nothing, EName (colName c)) | c <- tableColumns t ]
    expand (Item e alias) = Right [(alias, e)]

-- | Replace the aggregate calls of the result columns, HAVING and ORDER BY by slot references.
liftQuery :: [(Maybe String, Expr)] -> Select -> StateT [AggCall] (Either String) ([Expr], Maybe Expr, [OrderTerm])
liftQuery items sel = do
  es <- traverse (liftAggregates . snd) items
  h <- traverse liftAggregates (selHaving sel)
  o <- traverse (\t -> (\e -> t { otExpr = e }) <$> liftAggregates (otExpr t)) (selOrderBy sel)
  pure (es, h, o)

groupByAggregate :: String
groupByAggregate = "aggregate functions are not allowed in the GROUP BY clause"

-- | A GROUP BY term: an integer is a result column's position (SPEC 3.3), anything else an expression.
groupKey :: Scope -> [(Maybe String, Expr)] -> [Bound] -> Int -> Expr -> Either String Bound
groupKey scope items results pos term = case term of
  ELit (VInt k) -> ordinal k
  EUnary Neg (ELit (VInt k)) -> ordinal (negate k)
  e | isJust (containsAggregate e) -> Left groupByAggregate
    | otherwise -> bindExpr scope e
  where
    ordinal k
      | k >= 1 && k <= length results
      , (_, e) <- items !! (k - 1) = maybe (Right (results !! (k - 1))) (const (Left groupByAggregate)) (containsAggregate e)
      | otherwise = Left (ordinalName pos ++ " GROUP BY term out of range - should be between 1 and "
                          ++ show (length results))

-- | Rows with equal key values form a group, groups in key order; without GROUP BY one group, even if empty.
groupsOf :: [Bound] -> [[Value]] -> [[[Value]]]
groupsOf [] rows = [rows]
groupsOf keys rows =
  map reverse (Map.elems (Map.fromListWith (++) [ (map (ValueKey . evalExpr r) keys, [r]) | r <- rows ]))

-- | The row a group evaluates on: its bare-column row, then the value of each aggregate.
groupRow :: Int -> [AggSpec] -> [[Value]] -> Either String [Value]
groupRow width specs rows = (bareColumnRow width specs rows ++) <$> traverse (`computeAggregate` rows) specs

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

keyValue :: [Value] -> [Value] -> SortKey -> Value
keyValue out _ (FromResult i) = out !! i
keyValue _ row (FromRow b) = evalExpr row b

-- | LIMIT / OFFSET expressions have no row in scope.
constantInt :: Expr -> Either String Int
constantInt e = do
  b <- bindExpr emptyScope e
  Right $ case toNumber (evalExpr [] b) of
    VInt n -> n
    VReal d -> truncate d
    _ -> 0

-- | A negative LIMIT means no limit; a negative OFFSET counts as 0.
limitRows :: Maybe Int -> Maybe Int -> [a] -> [a]
limitRows lim off rows = maybe id limit lim (drop (maybe 0 (max 0) off) rows)
  where limit n = if n < 0 then id else take n

