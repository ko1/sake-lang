-- | Operators on values: arithmetic, concatenation, comparison with affinity,
-- and three-valued logic (SPEC 1.8, 1.9).
module Engine.Operators
  ( unaryOp
  , binaryOp
  , convertToAffinity
  , likeOp
  , castValue
  ) where

import Data.Array.Unboxed (UArray, listArray, (!))
import Data.Char (isDigit)
import qualified Data.IntSet as IntSet
import Data.Int (Int64)
import Engine.Syntax (BinOp (..), UnOp (..))
import Engine.Value

-- | Apply a unary operator.
unaryOp :: UnOp -> Value -> Value
unaryOp Pos v = v
unaryOp Neg v = case toNumber v of
  VNull -> VNull
  VInt i -> VInt (negate i)
  VReal d -> VReal (negate d)
  other -> other
unaryOp Not v = fromBool (not <$> truthValue v)

-- | A binary operator given the affinities of its operands (needed by comparisons only).
binaryOp :: BinOp -> Maybe ColType -> Maybe ColType -> Value -> Value -> Value
binaryOp op ta tb = case op of
  Add -> arith op
  Sub -> arith op
  Mul -> arith op
  Div -> arith op
  Mod -> arith op
  Concat -> concatenate
  Eq -> compareWith (== EQ)
  Ne -> compareWith (/= EQ)
  Lt -> compareWith (== LT)
  Le -> compareWith (/= GT)
  Gt -> compareWith (== GT)
  Ge -> compareWith (/= LT)
  Is -> isOp id
  IsNot -> isOp not
  And -> \a b -> fromBool (andT (truthValue a) (truthValue b))
  Or -> \a b -> fromBool (orT (truthValue a) (truthValue b))
  where
    compareWith test a b
      | a == VNull || b == VNull = VNull
      | otherwise = let (a', b') = applyAffinity ta tb a b
                     in fromBool (Just (test (compareValues a' b')))
    isOp f a b = case (a, b) of
      (VNull, VNull) -> fromBool (Just (f True))
      (VNull, _) -> fromBool (Just (f False))
      (_, VNull) -> fromBool (Just (f False))
      _ -> let (a', b') = applyAffinity ta tb a b
            in fromBool (Just (f (compareValues a' b' == EQ)))

andT, orT :: Maybe Bool -> Maybe Bool -> Maybe Bool
andT (Just False) _ = Just False
andT _ (Just False) = Just False
andT (Just True) (Just True) = Just True
andT _ _ = Nothing
orT (Just True) _ = Just True
orT _ (Just True) = Just True
orT (Just False) (Just False) = Just False
orT _ _ = Nothing

-- | Read a non-NULL value as a number: text by numeric prefix.
toNumber :: Value -> Value
toNumber (VText s) = numericPrefix s
toNumber (VBlob s) = numericPrefix s
toNumber v = v

-- | Comparison conversions of SPEC 1.9.
applyAffinity :: Maybe ColType -> Maybe ColType -> Value -> Value -> (Value, Value)
applyAffinity ta tb a b
  | Just t <- ta, isNum t, not (maybe False isNum tb) = (a, convertToAffinity t b)
  | Just t <- tb, isNum t, not (maybe False isNum ta) = (convertToAffinity t a, b)
  | ta == Just CText && tb == Nothing = (a, convertToAffinity CText b)
  | tb == Just CText && ta == Nothing = (convertToAffinity CText a, b)
  | otherwise = (a, b)
  where
    isNum t = t == CInteger || t == CReal

-- | Convert a value toward a column affinity: numeric text becomes a number
-- for INTEGER/REAL, a number becomes its text form for TEXT; anything else stays
-- (a BLOB never changes, and a BLOB column has no affinity).
convertToAffinity :: ColType -> Value -> Value
convertToAffinity CBlob v = v
convertToAffinity CText v@(VInt _) = VText (textForm v)
convertToAffinity CText v@(VReal _) = VText (textForm v)
convertToAffinity CText v = v
convertToAffinity _ v@(VText s) = maybe v id (parseNumericLiteral s)
convertToAffinity _ v = v

-- | @x LIKE p@ (SPEC 2.3): NULL if either is NULL, else 1 or 0.
likeOp :: Value -> Value -> Value
likeOp a p
  | a == VNull || p == VNull = VNull
  | otherwise = fromBool (Just (likeMatch (textForm p) (textForm a)))

-- | Whole-text match of a LIKE pattern, ignoring ASCII case. Simulates the
-- pattern as an automaton over its positions, so it cannot blow up.
likeMatch :: String -> String -> Bool
likeMatch pat = final . foldl step (close (IntSet.singleton 0))
  where
    n = length pat
    arr = listArray (0, max 0 (n - 1)) pat :: UArray Int Char
    at i = arr ! i
    close s = IntSet.foldr extend s s
    extend i acc
      | i < n && at i == '%' = IntSet.union acc (close (IntSet.singleton (i + 1)))
      | otherwise = acc
    step states c = close (IntSet.fromList
      [ if at i == '%' then i else i + 1
      | i <- IntSet.toList states, i < n, at i == '%' || at i == '_' || asciiLower [at i] == asciiLower [c] ])
    final states = IntSet.member n states

-- | @CAST(x AS type)@ (SPEC 2.3).
castValue :: ColType -> Value -> Value
castValue _ VNull = VNull
castValue CBlob v = case v of
  VBlob _ -> v
  VText s -> VBlob (utf8Bytes s)
  _ -> VBlob (textForm v)
castValue t (VBlob s) = castValue t (VText s)
castValue CText v = VText (textForm v)
castValue CInteger v = case v of
  VInt _ -> v
  VReal d -> VInt (clampInt (truncate d))
  VText s -> VInt (clampInt (integerPrefix (dropWhile (`elem` " \t\n\r") s)))
  _ -> VInt 0
castValue CReal v = case v of
  VInt i -> VReal (fromIntegral i)
  VReal _ -> v
  VText s -> case numericPrefix s of
    VInt i -> VReal (fromIntegral i)
    other -> other
  _ -> VReal 0

clampInt :: Integer -> Int64
clampInt i = fromInteger (max (fromIntegral (minBound :: Int64)) (min (fromIntegral (maxBound :: Int64)) i))

-- | The value of the longest prefix that is an optional sign and digits, else 0.
integerPrefix :: String -> Integer
integerPrefix s = case s of
  '-' : r -> negate (digits r)
  '+' : r -> digits r
  _ -> digits s
  where
    digits r = case span isDigit r of
      ("", _) -> 0
      (ds, _) -> read ds

concatenate :: Value -> Value -> Value
concatenate a b
  | a == VNull || b == VNull = VNull
  | otherwise = VText (textForm a ++ textForm b)

arith :: BinOp -> Value -> Value -> Value
arith op a b
  | a == VNull || b == VNull = VNull
  | otherwise = case (toNumber a, toNumber b) of
      (VInt x, VInt y) -> intOp op x y
      (x, y) -> realOp op (asDouble x) (asDouble y)
  where
    asDouble (VInt i) = fromIntegral i
    asDouble (VReal d) = d
    asDouble _ = 0

intOp :: BinOp -> Int64 -> Int64 -> Value
intOp Add x y = VInt (x + y)
intOp Sub x y = VInt (x - y)
intOp Mul x y = VInt (x * y)
intOp Div x y
  | y == 0 = VNull
  | y == -1 = VInt (negate x)
  | otherwise = VInt (x `quot` y)
intOp Mod x y
  | y == 0 = VNull
  | y == -1 = VInt 0
  | otherwise = VInt (x `rem` y)
intOp _ _ _ = VNull

realOp :: BinOp -> Double -> Double -> Value
realOp Add x y = VReal (x + y)
realOp Sub x y = VReal (x - y)
realOp Mul x y = VReal (x * y)
realOp Div x y
  | y == 0 = VNull
  | otherwise = VReal (x / y)
realOp Mod x y
  | yi == 0 = VNull
  | yi == -1 = VReal 0
  | otherwise = VReal (fromIntegral (xi `rem` yi))
  where
    xi = truncate x :: Int64
    yi = truncate y :: Int64
realOp _ _ _ = VNull
