-- | The scalar function library (SPEC 1.11, 2.4). To add a function, add one entry to 'functions'.
module Engine.Functions
  ( Function(..)
  , Arity(..)
  , lookupFunction
  , arityAccepts
  , AggKind(..)
  , aggregateSignature
  , isAggregateCall
  , WindowKind(..)
  , windowSignature
  , isWindowOnlyName
  ) where

import Data.Char (isAscii, toLower, toUpper)
import Data.List (isPrefixOf, tails)
import qualified Data.Map.Strict as Map
import Data.Maybe (listToMaybe)
import Data.Ratio ((%))
import Engine.Coerce (toNumber)
import Engine.Real (significantDigits)
import Engine.Value

data Arity = Exactly Int | AtLeast Int | Between Int Int

data Function = Function
  { fnArity :: Arity
  , fnImpl :: [Value] -> Value
  }

arityAccepts :: Arity -> Int -> Bool
arityAccepts (Exactly n) k = k == n
arityAccepts (AtLeast n) k = k >= n
arityAccepts (Between lo hi) k = k >= lo && k <= hi

-- | The aggregate functions (SPEC 3.2); their computation is in Engine.Aggregate.
data AggKind = AggCount | AggSum | AggTotal | AggAvg | AggMin | AggMax | AggGroupConcat
  deriving (Eq)

-- | Kind and accepted argument count of an aggregate, by folded name. count() with no
-- argument counts rows like count(*).
aggregateSignature :: String -> Maybe (AggKind, Arity)
aggregateSignature name = case name of
  "count" -> Just (AggCount, Between 0 1)
  "sum" -> Just (AggSum, Exactly 1)
  "total" -> Just (AggTotal, Exactly 1)
  "avg" -> Just (AggAvg, Exactly 1)
  "min" -> Just (AggMin, Exactly 1)
  "max" -> Just (AggMax, Exactly 1)
  "group_concat" -> Just (AggGroupConcat, Between 1 2)
  _ -> Nothing

-- | Is a call of this folded name with this many arguments an aggregate? min / max with two
-- or more arguments are the scalar functions.
isAggregateCall :: String -> Int -> Bool
isAggregateCall name n = case aggregateSignature name of
  Nothing -> False
  Just (kind, _) -> not ((kind == AggMin || kind == AggMax) && n >= 2)

-- | The functions that exist only as window functions (SPEC 6.3); their computation is in Engine.WindowEval.
data WindowKind
  = WkRowNumber | WkRank | WkDenseRank | WkPercentRank | WkCumeDist | WkNtile
  | WkLag | WkLead | WkFirstValue | WkLastValue | WkNthValue

-- | Kind and accepted argument count of a window-only function, by folded name.
windowSignature :: String -> Maybe (WindowKind, Arity)
windowSignature name = case name of
  "row_number" -> Just (WkRowNumber, Exactly 0)
  "rank" -> Just (WkRank, Exactly 0)
  "dense_rank" -> Just (WkDenseRank, Exactly 0)
  "percent_rank" -> Just (WkPercentRank, Exactly 0)
  "cume_dist" -> Just (WkCumeDist, Exactly 0)
  "ntile" -> Just (WkNtile, Exactly 1)
  "lag" -> Just (WkLag, Between 1 3)
  "lead" -> Just (WkLead, Between 1 3)
  "first_value" -> Just (WkFirstValue, Exactly 1)
  "last_value" -> Just (WkLastValue, Exactly 1)
  "nth_value" -> Just (WkNthValue, Exactly 2)
  _ -> Nothing

isWindowOnlyName :: String -> Bool
isWindowOnlyName = maybe False (const True) . windowSignature

-- | Look a function up by its folded (lower-case) name.
lookupFunction :: String -> Maybe Function
lookupFunction name = Map.lookup name functions

functions :: Map.Map String Function
functions = Map.fromList
  [ ("length", unary $ \v -> VInt (length (textForm v)))   -- a BLOB's text form has one Char per byte
  , ("hex", Function (Exactly 1) $ \args -> case args of
      [VNull] -> VText ""
      [v] -> VText (hexOf v)
      _ -> VNull)
  , ("upper", unary $ \v -> VText (map asciiUpper (textForm v)))
  , ("lower", unary $ \v -> VText (map asciiLower (textForm v)))
  , ("abs", unary absolute)
  , ("typeof", Function (Exactly 1) $ \args -> case args of
      [v] -> VText (typeOf v)
      _ -> VNull)
  , ("coalesce", Function (AtLeast 2) coalesce)
  , ("ifnull", Function (Exactly 2) coalesce)
  , ("nullif", Function (Exactly 2) $ \args -> case args of
      [x, y] | not (isNull x) && not (isNull y) && compareValues x y == EQ -> VNull
             | otherwise -> x
      _ -> VNull)
  , ("substr", strict (Between 2 3) substr)
  , ("trim", strict (Between 1 2) (trimWith True True))
  , ("ltrim", strict (Between 1 2) (trimWith True False))
  , ("rtrim", strict (Between 1 2) (trimWith False True))
  , ("replace", strict (Exactly 3) replaceText)
  , ("instr", strict (Exactly 2) instr)
  , ("round", strict (Between 1 2) roundValue)
  , ("max", strict (AtLeast 2) (extreme GT))
  , ("min", strict (AtLeast 2) (extreme LT))
  ]

-- | Function of any arity whose result is NULL when an argument is NULL.
strict :: Arity -> ([Value] -> Value) -> Function
strict arity f = Function arity (\args -> if any isNull args then VNull else f args)

-- | An integer argument (start, length, digits): TEXT by numeric prefix, REAL truncated.
intArg :: Value -> Int
intArg v = case toNumber v of
  VInt n -> n
  VReal d -> truncate d
  _ -> 0

-- | substr per SPEC 2.4; a missing length is infinite (Nothing).
substr :: [Value] -> Value
substr (x : start : rest) = isBlobLike (maybe id take' q'' (drop p'' text))
  where
    isBlobLike = case x of VBlob _ -> VBlob; _ -> VText
    text = textForm x
    len = length text
    p0 = intArg start
    q0 = fmap intArg (listToMaybe rest)
    (p1, q1)
      | p0 < 0 = let p = p0 + len in
          if p < 0 then (0, fmap (\q -> max 0 (q + p)) q0) else (p, q0)
      | p0 > 0 = (p0 - 1, q0)
      | otherwise = (0, fmap (\q -> if q > 0 then q - 1 else q) q0)
    (p'', q'') = case q1 of
      Just q | q < 0 -> let p = p1 + q in
        if p < 0 then (0, Just (negate q + p)) else (p, Just (negate q))
      _ -> (p1, q1)
    take' n = take (max 0 n)
substr _ = VNull

trimWith :: Bool -> Bool -> [Value] -> Value
trimWith front back (x : rest) = VText (dropBack (dropFront text))
  where
    text = textForm x
    chars = maybe " " textForm (listToMaybe rest)
    dropFront = if front then dropWhile (`elem` chars) else id
    dropBack = if back then reverse . dropWhile (`elem` chars) . reverse else id
trimWith _ _ [] = VNull

replaceText :: [Value] -> Value
replaceText [x, from, to]
  | null f = VText t
  | otherwise = VText (go t)
  where
    t = textForm x
    f = textForm from
    r = textForm to
    go [] = []
    go s@(c : cs) | f `isPrefixOf` s = r ++ go (drop (length f) s)
                  | otherwise = c : go cs
replaceText _ = VNull

-- | Uppercase hex of the bytes of a BLOB, or of the UTF-8 text form of any other value.
hexOf :: Value -> String
hexOf v = case displayForm (VBlob bytes) of
  _ : _ : ds -> init ds
  _ -> ""
  where bytes = case v of VBlob b -> b; _ -> utf8Bytes (textForm v)

instr :: [Value] -> Value
instr [x, y] = VInt (case [ i | (i, s) <- zip [1 ..] (tails (textForm x)), textForm y `isPrefixOf` s ] of
  i : _ -> i
  [] -> 0)
instr _ = VNull

-- | round per SPEC 2.4: the 17-significant-digit decimal form, rounded half away from zero.
roundValue :: [Value] -> Value
roundValue (x : rest) = VReal (signed (roundDigits places (abs d)))
  where
    d = case toNumber x of
      VInt n -> fromIntegral n
      VReal y -> y
      _ -> 0
    places = maybe 0 (max 0 . intArg) (listToMaybe rest)
    signed r = if d < 0 then negate r else r
roundValue [] = VNull

roundDigits :: Int -> Double -> Double
roundDigits places x
  | x == 0 = 0
  | otherwise = fromRational (m % (10 ^ places))
  where
    (n, e) = significantDigits 17 x
    shift = e - 16 + places            -- n * 10^shift is x scaled by 10^places
    m | shift >= 0 = n * 10 ^ shift
      | otherwise = let (q, rm) = n `divMod` (10 ^ negate shift) in
          if rm * 2 >= 10 ^ negate shift then q + 1 else q

-- | max / min: the first of equal values wins; 'GT' picks the largest, 'LT' the smallest.
extreme :: Ordering -> [Value] -> Value
extreme want (v : vs) = foldl (\best x -> if compareValues x best == want then x else best) v vs
extreme _ [] = VNull

-- | One-argument function that maps NULL to NULL.
unary :: (Value -> Value) -> Function
unary f = Function (Exactly 1) $ \args -> case args of
  [VNull] -> VNull
  [v] -> f v
  _ -> VNull

asciiUpper, asciiLower :: Char -> Char
asciiUpper c = if isAscii c then toUpper c else c
asciiLower c = if isAscii c then toLower c else c

absolute :: Value -> Value
absolute (VInt n) = VInt (abs n)
absolute (VReal d) = VReal (abs d)
absolute v = case toNumber v of
  VInt n -> VReal (abs (fromIntegral n))
  VReal d -> VReal (abs d)
  _ -> VNull

typeOf :: Value -> String
typeOf VNull = "null"
typeOf (VInt _) = "integer"
typeOf (VReal _) = "real"
typeOf (VText _) = "text"
typeOf (VBlob _) = "blob"

coalesce :: [Value] -> Value
coalesce args = case filter (not . isNull) args of
  v : _ -> v
  [] -> VNull
