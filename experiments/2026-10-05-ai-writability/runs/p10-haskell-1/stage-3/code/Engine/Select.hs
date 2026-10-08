-- | Execution of SELECT (SPEC 1.7).
module Engine.Select (executeSelect) where

import Data.Foldable (toList)
import Control.Monad (when)
import Data.List (findIndex, groupBy, intercalate, nub, sortBy, sortOn)
import Data.Maybe (fromMaybe, isJust, maybeToList)
import Engine.Aggregate (aggregateCalls)
import Engine.Catalog
import Engine.Compile
import Engine.Error
import Engine.Grouping
import Engine.Sorting (compareKeys)
import Engine.Syntax
import Engine.Value

-- | How an ORDER BY term gets its value for a row.
data SortKey
  = ByResult Int -- ^ the n-th (0-based) result column
  | ByExpr RowFn

-- | Run a SELECT, returning the printed lines.
executeSelect :: Database -> SelectStmt -> Result [String]
executeSelect db s = do
  (table, rows) <- case selFrom s of
    Nothing -> Right (Nothing, [[]])
    Just name -> do
      t <- findTable name db `orElse` noSuchTable name
      Right (Just (name, t), toList (tableRows t))
  let columns = maybe [] (tableColumns . snd) table
      baseScope = tableScope (fst <$> table) columns
  items <- expandColumns table (selColumns s)
  let aliasScope = baseScope {scopeAliases = [(a, e) | (e, Just a) <- items]}
      terms = selOrderBy s
      calls = nub (concatMap aggregateCalls (map fst items ++ maybeToList (selHaving s) ++ [e | OrderTerm e _ _ <- terms]))
      isAggregate = not (null (selGroupBy s)) || any (not . null . aggregateCalls . fst) items
  whereFn <- traverse (fmap snd . compileExpr aliasScope) (selWhere s)
  when (not isAggregate && isJust (selHaving s)) (Left havingNonAggregate)
  let kept = [r | r <- rows, maybe True (\f -> truthValue (f r) == Just True) whereFn]
  -- The rows result columns, HAVING and ORDER BY are evaluated on, and the scope for their names.
  (sources, scope) <-
    if isAggregate
      then do
        keyFns <- mapM (compileGroupTerm aliasScope items) (zip [1 ..] (selGroupBy s))
        plans <- mapM (planAggregate baseScope) calls
        let width = length columns
            slotScope = aliasScope {scopeAggs = AggregateSlots (zip calls [width ..])}
        havingFn <- traverse (fmap snd . compileExpr slotScope) (selHaving s)
        groups <- mapM (presentGroup width plans) (groupRows keyFns kept)
        Right ([g | g <- groups, maybe True (\f -> truthValue (f g) == Just True) havingFn], slotScope)
      else Right (kept, aliasScope {scopeAggs = NoAggregates misuseOfAggregateAlias misuseOfAggregateAlias})
  resultFns <- mapM (fmap snd . compileExpr scope . fst) items
  keys <- mapM (compileOrderTerm scope items) (zip [1 ..] terms)
  limit <- traverse compileCount (selLimit s)
  offset <- traverse compileCount (selOffset s)
  let evaluated = map (evalRow resultFns keys) sources
      distinct = if selDistinct s then dedupe fst evaluated else evaluated
      sorted = map fst (sortBy (\(_, a) (_, b) -> compareKeys terms a b) distinct)
      afterOffset = drop (max 0 (fromMaybe 0 offset)) sorted
      limited = case limit of
        Just n | n >= 0 -> take n afterOffset
        _ -> afterOffset
  Right (map (intercalate "|" . map textForm) limited)

-- | Keep the first of each run of equal items (by the key's values, NULLs equal), in order.
dedupe :: (a -> [Value]) -> [a] -> [a]
dedupe key xs =
  map (snd . snd) . sortOn (fst . snd) . map head . groupBy (\a b -> sameKey a b)
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
evalRow :: [RowFn] -> [SortKey] -> Row -> ([Value], [Value])
evalRow resultFns keys r = (results, map keyValue keys)
  where
    results = map ($ r) resultFns
    keyValue (ByResult i) = results !! i
    keyValue (ByExpr f) = f r

compileCount :: Expr -> Result Int
compileCount e = evalCount . snd <$> compileExpr noRowScope e

-- | Result columns as (expression, alias); @*@ becomes the table's columns.
expandColumns :: Maybe (Ident, Table) -> [ResultCol] -> Result [(Expr, Maybe Ident)]
expandColumns table cols = concat <$> mapM expand cols
  where
    expand (ResultExpr e a) = Right [(e, a)]
    expand Star = case table of
      Nothing -> Left noTablesSpecified
      Just (_, t) -> Right [(EColumn Nothing (columnName c), Nothing) | c <- tableColumns t]

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
evalCount f = case f [] of
  VInt i -> fromIntegral i
  VReal d -> truncate d
  VText t -> case numericPrefix t of
    VInt i -> fromIntegral i
    VReal d -> truncate d
    _ -> 0
  VNull -> 0
