-- | Aggregate functions (SPEC 3.2): which calls are aggregates, and how a
-- group's values are folded into one. Knows nothing about rows or scopes.
module Engine.Aggregate
  ( AggCall (..)
  , asAggregate
  , aggregateCalls
  , AggImpl (..)
  , resolveAggregate
  ) where

import Data.Int (Int64)
import Engine.Error
import Engine.Syntax
import Engine.Value

-- | An aggregate call in the syntax tree.
data AggCall = AggCall
  { acName :: Ident -- ^ as written (error messages spell it so)
  , acDistinct :: Bool
  , acArgs :: [Expr]
  , acOrder :: [OrderTerm]
  }

-- | Recognise an aggregate call. @max@/@min@ with two or more arguments are
-- the scalar functions, unless written with DISTINCT or ORDER BY.
asAggregate :: Expr -> Maybe AggCall
asAggregate (ECall n args)
  | isAggregateName n (length args) = Just (AggCall n False args [])
asAggregate (EAggregate n d args order)
  | identKey n `elem` aggregateNames = Just (AggCall n d args order)
asAggregate _ = Nothing

aggregateNames :: [String]
aggregateNames = ["count", "sum", "total", "avg", "min", "max", "group_concat"]

isAggregateName :: Ident -> Int -> Bool
isAggregateName n argc
  | k `elem` ["min", "max"] = argc == 1
  | otherwise = k `elem` aggregateNames
  where
    k = identKey n

-- | The outermost aggregate calls of an expression, in order, as the expressions themselves.
aggregateCalls :: Expr -> [Expr]
aggregateCalls e
  | Just _ <- asAggregate e = [e]
  | otherwise = concatMap aggregateCalls (childExprs e)

-- | How to fold one group. The input is the argument values of the group's
-- rows (already in ORDER BY order), one list of values per row.
data AggImpl = AggImpl
  { aggFold :: [[Value]] -> Result Value
  , aggExtreme :: Maybe Ordering -- ^ min (LT) / max (GT): the row giving the result is the group's bare-column row
  }

-- | Check name, argument count and DISTINCT, and pick the implementation.
-- The collation is that of the first argument: DISTINCT, min and max compare its values under it.
resolveAggregate :: Collation -> AggCall -> Result AggImpl
resolveAggregate coll (AggCall name distinct args _) = do
  let argc = length args
      k = identKey name
  if k == "group_concat" && distinct && argc == 2
    then Left distinctArity
    else Right ()
  let wrong = Left (wrongArgCount name)
      uniq = if distinct then distinctRows coll else id
      oneArg f = if argc == 1 then Right (AggImpl (f . uniq) Nothing) else wrong
  case k of
    "count" -> case argc of
      0 | not distinct -> Right (AggImpl (Right . VInt . fromIntegral . length) Nothing)
      1 -> Right (AggImpl (Right . VInt . fromIntegral . length . nonNull . uniq) Nothing)
      _ -> wrong
    "sum" -> oneArg (sumOf . nonNull)
    "total" -> oneArg (fmap toReal . sumOf' . nonNull)
    "avg" -> oneArg (average . nonNull)
    "min" -> if argc == 1 then Right (AggImpl (Right . extreme coll LT . nonNull . uniq) (Just LT)) else wrong
    "max" -> if argc == 1 then Right (AggImpl (Right . extreme coll GT . nonNull . uniq) (Just GT)) else wrong
    "group_concat"
      | argc == 1 || argc == 2 -> Right (AggImpl (Right . groupConcat . uniq) Nothing)
      | otherwise -> wrong
    _ -> Left (noSuchFunction name)
  where
    toReal (VInt i) = VReal (fromIntegral i)
    toReal (VNull) = VReal 0
    toReal v = v

-- | Keep the rows whose first value is not NULL, as that value.
nonNull :: [[Value]] -> [Value]
nonNull rows = [v | (v : _) <- rows, v /= VNull]

-- | Keep the first row of each distinct first value (a NULL stays; it is skipped later).
distinctRows :: Collation -> [[Value]] -> [[Value]]
distinctRows coll = go []
  where
    go _ [] = []
    go seen (r : rs) = case r of
      v : _ | v /= VNull, any (\s -> compareValuesWith coll s v == EQ) seen -> go seen rs
            | otherwise -> r : go (v : seen) rs
      [] -> go seen rs

extreme :: Collation -> Ordering -> [Value] -> Value
extreme _ _ [] = VNull
extreme coll want (v : vs) = foldl' (\best x -> if compareValuesWith coll x best == want then x else best) v vs

-- | How a value takes part in a sum.
data Term = TInt Integer | TReal Double

term :: Value -> Term
term v = case v of
  VInt i -> TInt (toInteger i)
  VReal d -> TReal d
  VText s -> case parseNumericLiteral s of
    Just (VInt i) -> TInt (toInteger i)
    Just (VReal d) -> TReal d
    _ -> TReal (asDouble (numericPrefix s))
  VNull -> TInt 0
  where
    asDouble (VInt i) = fromIntegral i
    asDouble (VReal d) = d
    asDouble _ = 0

-- | @sum@: NULL when empty, exact INTEGER when all are INTEGER, else the REAL sum.
sumOf :: [Value] -> Result Value
sumOf [] = Right VNull
sumOf vs = sumOf' vs

-- | The sum of 'sumOf' with 0 for no values (INTEGER 0 when empty).
sumOf' :: [Value] -> Result Value
sumOf' vs = case span isInt terms of
  (ints, []) -> let n = sum [i | TInt i <- ints] in
    if n < fromIntegral (minBound :: Int64) || n > fromIntegral (maxBound :: Int64)
      then Left integerOverflow
      else Right (VInt (fromInteger n))
  (ints, rest) -> Right (VReal (compensated (fromInteger (sum [i | TInt i <- ints])) rest))
  where
    terms = map term vs
    isInt (TInt _) = True
    isInt _ = False

-- | Kahan-Babuska summation as specified in SPEC 3.2.
compensated :: Double -> [Term] -> Double
compensated s0 = finish . foldl' step (s0, 0)
  where
    finish (s, c) = s + c
    step (s, c) t =
      let v = case t of TInt i -> fromInteger i; TReal d -> d
          s' = s + v
          c' = if abs s > abs v then c + ((s - s') + v) else c + ((v - s') + s)
       in (s', c')

average :: [Value] -> Result Value
average [] = Right VNull
average vs = do
  total <- sumOf' vs
  let s = case total of VInt i -> fromIntegral i; VReal d -> d; _ -> 0
  Right (VReal (s / fromIntegral (length vs)))

-- | Rows are @[x]@ or @[x, sep]@; the separator before a value is its own row's.
groupConcat :: [[Value]] -> Value
groupConcat rows = case [(sepOf r, textForm v) | r@(v : _) <- rows, v /= VNull] of
  [] -> VNull
  (_, first) : more -> VText (first ++ concat [sep ++ t | (sep, t) <- more])
  where
    sepOf (_ : s : _) = if s == VNull then "" else textForm s
    sepOf _ = ","
