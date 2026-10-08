-- | Execution of SELECT (SPEC 1.7).
module Engine.Select (executeSelect) where

import Data.Foldable (toList)
import Data.List (findIndex, intercalate, sortBy)
import Data.Maybe (fromMaybe)
import Engine.Catalog
import Engine.Compile
import Engine.Error
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
      baseScope = Scope (fst <$> table) columns []
  items <- expandColumns table (selColumns s)
  let aliasScope = baseScope {scopeAliases = [(a, e) | (e, Just a) <- items]}
  resultFns <- mapM (fmap snd . compileExpr baseScope . fst) items
  whereFn <- traverse (fmap snd . compileExpr aliasScope) (selWhere s)
  keys <- mapM (compileOrderTerm aliasScope items) (zip [1 ..] (selOrderBy s))
  limit <- traverse (compileCount) (selLimit s)
  offset <- traverse (compileCount) (selOffset s)
  let kept = [r | r <- rows, maybe True (\f -> truthValue (f r) == Just True) whereFn]
      withKeys = map (evalRow resultFns keys) kept
      sorted = map fst (sortBy (\(_, a) (_, b) -> compareKeys (selOrderBy s) a b) withKeys)
      afterOffset = drop (max 0 (fromMaybe 0 offset)) sorted
      limited = case limit of
        Just n | n >= 0 -> take n afterOffset
        _ -> afterOffset
  Right (map (intercalate "|" . map textForm) limited)

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

compareKeys :: [OrderTerm] -> [Value] -> [Value] -> Ordering
compareKeys terms as bs = mconcat (zipWith3 one terms as bs)
  where
    one (OrderTerm _ desc nullsFirst) a b = case (a, b) of
      (VNull, VNull) -> EQ
      (VNull, _) -> if first then LT else GT
      (_, VNull) -> if first then GT else LT
      _ -> (if desc then flip else id) compareValues a b
      where
        first = fromMaybe (not desc) nullsFirst

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
