-- | Aggregate functions (SPEC 3.2): finding the calls in a query, binding them, and computing
-- them over the rows of a group. Query evaluation (Engine.Query) does the grouping.
module Engine.Aggregate
  ( AggSpec
  , containsAggregate
  , liftAggregates
  , checkCall
  , bindAggregate
  , computeAggregate
  , bareColumnRow
  ) where

import Control.Monad.State.Strict (StateT, get, put, lift)
import Data.List (findIndex, sortBy)
import Data.Maybe (listToMaybe)
import Engine.Ast
import Engine.Coerce (numericPrefix, parseNumberText)
import Engine.Expr
import Engine.Scope
import Engine.Functions
import Engine.Names (foldName)
import Engine.Sorting
import Engine.Value

-- | An aggregate call whose arguments are bound against the columns of the table.
data AggSpec = AggSpec
  { asKind :: AggKind
  , asDistinct :: Bool
  , asStar :: Bool                  -- count(*) (or count()): no argument
  , asArgs :: [Bound]
  , asOrder :: [(OrderTerm, Bound)] -- ORDER BY inside the call
  }

-- Finding calls in expressions ----------------------------------------------------

-- | The call, if this node is one: a plain call of an aggregate name, or a call with '*' / DISTINCT / ORDER BY.
asAggCall :: Expr -> Maybe AggCall
asAggCall (ECall n args)
  | isAggregateCall (foldName n) (length args) = Just (AggCall n False False args [])
asAggCall (EAggCall c) = Just c
asAggCall _ = Nothing

-- | The name (as written) of the first aggregate call in the expression.
containsAggregate :: Expr -> Maybe String
containsAggregate e = case asAggCall e of
  Just c -> Just (acName c)
  Nothing -> listToMaybe [ n | Just n <- map containsAggregate (subExpressions e) ]

-- | Replace each aggregate call by a reference to its slot in the list of calls collected so far
-- (identical calls share a slot). Calls are validated here (SPEC 3.2 errors).
liftAggregates :: Expr -> StateT [AggCall] (Either String) Expr
liftAggregates e = case asAggCall e of
  Just c -> do
    lift (checkCall c)
    EAggRef <$> slotFor c { acName = foldName (acName c) }
  Nothing -> traverseExpr liftAggregates e
  where
    slotFor c = do
      calls <- get
      case findIndex (== c) calls of
        Just k -> pure k
        Nothing -> put (calls ++ [c]) >> pure (length calls)

kindOf :: AggCall -> Either String (AggKind, Arity)
kindOf c = maybe (Left "syntax error") Right (aggregateSignature (foldName (acName c)))

checkCall :: AggCall -> Either String ()
checkCall c = do
  (kind, arity) <- kindOf c
  let n = length (acArgs c)
      wrong = Left ("wrong number of arguments to function " ++ acName c ++ "()")
  if acDistinct c && kind == AggGroupConcat && n == 2
    then Left "DISTINCT aggregates must have exactly one argument"
    else if acStar c && kind /= AggCount then wrong
    else if arityAccepts arity n then Right () else wrong

-- Binding ----------------------------------------------------------------------------

-- | Bind a lifted call (argument expressions resolve against the table's columns).
bindAggregate :: Scope -> AggCall -> Either String AggSpec
bindAggregate scope c = do
  (kind, _) <- kindOf c
  args <- traverse (bindExpr scope) (acArgs c)
  order <- traverse (\t -> (,) t <$> bindExpr scope (otExpr t)) (acOrder c)
  Right (AggSpec kind (acDistinct c) (acStar c || null args) args order)

-- Computing -----------------------------------------------------------------------------

-- | The value of the aggregate over the rows of a group.
computeAggregate :: Env -> AggSpec -> [[Value]] -> Either String Value
computeAggregate ctx spec rows0 = case asKind spec of
  AggCount | asStar spec -> Right (VInt (length rows))
  AggCount -> Right (VInt (length values))
  AggSum -> case sumOf values of
    Nothing -> Right VNull
    Just (SumInt n) | n > toInteger (maxBound :: Int) || n < toInteger (minBound :: Int) -> Left "integer overflow"
                    | otherwise -> Right (VInt (fromInteger n))
    Just (SumReal d) -> Right (VReal d)
  AggTotal -> Right . VReal $ case sumOf values of
    Nothing -> 0
    Just s -> sumAsReal s
  AggAvg -> Right $ case sumOf values of
    Nothing -> VNull
    Just s -> VReal (sumAsReal s / fromIntegral (length values))
  AggMin -> Right (extreme LT)
  AggMax -> Right (extreme GT)
  AggGroupConcat -> Right $ case [ (v, sep r) | (r, v) <- present ] of
    [] -> VNull
    (v, _) : rest -> VText (textForm v ++ concat [ s ++ textForm x | (x, s) <- rest ])
  where
    rows
      | null (asOrder spec) = rows0
      | otherwise = map snd (sortBy (\a b -> compareByTerms terms (fst a) (fst b))
                                    [ (map (\(_, b) -> evalExpr (r : ctx) b) (asOrder spec), r) | r <- rows0 ])
    terms = map fst (asOrder spec)
    firstArg r = case asArgs spec of
      b : _ -> evalExpr (r : ctx) b
      [] -> VNull
    -- (row, argument) for rows whose argument is not NULL, after DISTINCT
    present
      | asDistinct spec = distinctOn (ValueKey . snd) nonNull
      | otherwise = nonNull
      where nonNull = [ (r, v) | r <- rows, let v = firstArg r, not (isNull v) ]
    values = map snd present
    sep r = case asArgs spec of
      [_, b] -> case evalExpr (r : ctx) b of
        VNull -> ""
        s -> textForm s
      _ -> ","
    extreme want = case values of
      v : vs -> foldl (\best x -> if compareValues x best == want then x else best) v vs
      [] -> VNull

-- | An exact INTEGER sum, or a REAL one.
data Sum = SumInt Integer | SumReal Double

sumAsReal :: Sum -> Double
sumAsReal (SumInt n) = fromInteger n
sumAsReal (SumReal d) = d

-- | SPEC 3.2 "Sums": exact while every value is an INTEGER, else compensated in REAL from the first non-INTEGER on.
sumOf :: [Value] -> Maybe Sum
sumOf [] = Nothing
sumOf vs = Just $ case break (not . isInt) nums of
  (ints, []) -> SumInt (sum [ n | Left n <- ints ])
  (ints, rest) -> SumReal (compensated (fromInteger (sum [ n | Left n <- ints ])) (map asReal rest))
  where
    nums = map classify vs
    isInt = either (const True) (const False)
    asReal = either fromInteger id

-- | An INTEGER (Left) or a REAL (Right): TEXT that is a numeric literal counts as that number, other TEXT as its prefix.
classify :: Value -> Either Integer Double
classify (VInt n) = Left (toInteger n)
classify (VReal d) = Right d
classify (VText s) = case parseNumberText s of
  Just (VInt n) -> Left (toInteger n)
  Just (VReal d) -> Right d
  _ -> Right (realOf (numericPrefix s))
-- a BLOB is never a numeric literal: always read by prefix of its text form (SPEC 7.3)
classify (VBlob s) = Right (realOf (numericPrefix s))
classify VNull = Right 0

realOf :: Value -> Double
realOf (VInt n) = fromIntegral n
realOf (VReal d) = d
realOf _ = 0

-- | Neumaier-style compensated sum exactly as SPEC 3.2 gives it.
compensated :: Double -> [Double] -> Double
compensated s0 vs = s + c
  where
    (s, c) = foldl step (s0, 0) vs
    step (s', c') v =
      let t = s' + v
          c'' = if abs s' > abs v then c' + ((s' - t) + v) else c' + ((v - t) + s')
      in (t, c'')

-- Bare columns --------------------------------------------------------------------------

-- | The row a group's bare columns come from (SPEC 3.3): with one aggregate call, a min / max,
-- the row that gave the extreme; otherwise the first row; NULLs for an empty group.
bareColumnRow :: Env -> Int -> [AggSpec] -> [[Value]] -> [Value]
bareColumnRow _ width _ [] = replicate width VNull
bareColumnRow ctx _ [spec] rows@(first : _)
  | asKind spec `elem` [AggMin, AggMax], [arg] <- asArgs spec =
      let want = if asKind spec == AggMin then LT else GT
          better (bv, _) (v, _) = not (isNull v) && (isNull bv || compareValues v bv == want)
          pick best cand = if better best cand then cand else best
      in case [ (evalExpr (r : ctx) arg, r) | r <- rows ] of
           c : cs -> snd (foldl pick c cs)
           [] -> first
  | otherwise = first
bareColumnRow _ _ _ (first : _) = first
