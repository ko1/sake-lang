-- | SELECT evaluation (SPEC 1.7): name resolution, WHERE, ORDER BY, LIMIT / OFFSET.
module Engine.Query
  ( runSelect
  ) where

import Data.Foldable (toList)
import Data.List (sortBy)
import Data.Maybe (fromMaybe)
import Engine.Ast
import Engine.Catalog
import Engine.Coerce (toNumber, truthOf)
import Engine.Expr
import Engine.Names (foldName)
import Engine.Value

-- | A result column: its alias (if written) and how to compute it.
data ResultCol = ResultCol { rcAlias :: Maybe String, rcBound :: Bound }

-- | Where an ORDER BY term takes its value from.
data SortKey = FromResult Int | FromRow Bound

-- | Rows of the result, as values.
runSelect :: Database -> Select -> Either String [[Value]]
runSelect db sel = do
  tbl <- case selFrom sel of
    Nothing -> Right Nothing
    Just name -> maybe (Left ("no such table: " ++ name)) (Right . Just) (lookupTable name db)
  let cols = maybe [] tableColumns tbl
      sourceRows = maybe [[]] (toList . tableRows) tbl
  results <- concat <$> traverse (expandItem tbl (Scope cols [])) (selItems sel)
  let aliases = [ (foldName a, (i, rcBound rc)) | (i, rc) <- zip [0 ..] results, Just a <- [rcAlias rc] ]
      scope = Scope cols [ (a, b) | (a, (_, b)) <- aliases ]
  cond <- traverse (bindExpr scope) (selWhere sel)
  keys <- traverse (uncurry (sortKey scope aliases (length results)))
                   (zip [1 ..] (selOrderBy sel))
  lim <- traverse constantInt (selLimit sel)
  off <- traverse constantInt (selOffset sel)
  let kept = filter (\r -> maybe True (\c -> truthOf (evalExpr r c) == Just True) cond) sourceRows
      withKeys = [ (out, [ keyValue out r k | k <- keys ])
                 | r <- kept, let out = [ evalExpr r (rcBound rc) | rc <- results ] ]
      sorted = sortBy (compareKeys (selOrderBy sel)) withKeys
  Right (limitRows lim off (map fst sorted))

expandItem :: Maybe Table -> Scope -> SelectItem -> Either String [ResultCol]
expandItem Nothing _ Star = Left "no tables specified"
expandItem (Just t) _ Star =
  Right [ ResultCol Nothing (BCol i (colType c)) | (i, c) <- zip [0 ..] (tableColumns t) ]
expandItem _ scope (Item e alias) = (\b -> [ResultCol alias b]) <$> bindExpr scope e

sortKey :: Scope -> [(String, (Int, Bound))] -> Int -> Int -> OrderTerm -> Either String SortKey
sortKey scope aliases nResults pos term = case otExpr term of
  EName n | Just (i, _) <- lookup (foldName n) aliases -> Right (FromResult i)
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

-- | Terms compared in turn; NULLs first under ASC, last under DESC unless NULLS says otherwise.
compareKeys :: [OrderTerm] -> ([Value], [Value]) -> ([Value], [Value]) -> Ordering
compareKeys terms (_, ka) (_, kb) = mconcat (zipWith3 cmp terms ka kb)
  where
    cmp term a b = case (isNull a, isNull b) of
      (True, True) -> EQ
      (True, False) -> if nullsFirst then LT else GT
      (False, True) -> if nullsFirst then GT else LT
      _ -> (if otDesc term then flip else id) compareValues a b
      where nullsFirst = fromMaybe (if otDesc term then NullsLast else NullsFirst) (otNulls term) == NullsFirst

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

