-- | Operators on values: arithmetic, concatenation, comparison with affinity,
-- and three-valued logic (SPEC 1.8, 1.9).
module Engine.Operators
  ( unaryOp
  , binaryOp
  ) where

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
toNumber v = v

-- | Comparison conversions of SPEC 1.9.
applyAffinity :: Maybe ColType -> Maybe ColType -> Value -> Value -> (Value, Value)
applyAffinity ta tb a b
  | isNum ta && not (isNum tb) = (a, numify b)
  | isNum tb && not (isNum ta) = (numify a, b)
  | ta == Just CText && tb == Nothing = (a, textify b)
  | tb == Just CText && ta == Nothing = (textify a, b)
  | otherwise = (a, b)
  where
    isNum t = t == Just CInteger || t == Just CReal
    numify v@(VText s) = maybe v id (parseNumericLiteral s)
    numify v = v
    textify v@(VInt _) = VText (textForm v)
    textify v@(VReal _) = VText (textForm v)
    textify v = v

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
