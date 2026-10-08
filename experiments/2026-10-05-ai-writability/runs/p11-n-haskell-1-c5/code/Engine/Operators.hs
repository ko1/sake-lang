-- | Operators on values: arithmetic, concatenation, comparison with affinity,
-- and three-valued logic (SPEC 1.8, 1.9).
module Engine.Operators
  ( unaryOp
  , binaryOp
  , convertToAffinity
  , likeOp
  , likeEscapeOp
  , globOp
  , castValue
  ) where

import Control.Exception (throw)
import Data.Array.Unboxed (Array, listArray, (!))
import Data.Char (isDigit)
import qualified Data.IntSet as IntSet
import Data.Int (Int64)
import Engine.Error (SqlFailure (..), escapeNotSingleChar)
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
  | Just t <- ta, isNum t, not (maybe False isNum tb) = (a, convertToAffinity t b)
  | Just t <- tb, isNum t, not (maybe False isNum ta) = (convertToAffinity t a, b)
  | ta == Just CText && tb == Nothing = (a, convertToAffinity CText b)
  | tb == Just CText && ta == Nothing = (convertToAffinity CText a, b)
  | otherwise = (a, b)
  where
    isNum t = t == CInteger || t == CReal

-- | Convert a value toward a column affinity: numeric text becomes a number
-- for INTEGER/REAL, a number becomes its text form for TEXT; anything else stays.
convertToAffinity :: ColType -> Value -> Value
convertToAffinity CText v@(VInt _) = VText (textForm v)
convertToAffinity CText v@(VReal _) = VText (textForm v)
convertToAffinity CText v = v
convertToAffinity _ v@(VText s) = maybe v id (parseNumericLiteral s)
convertToAffinity _ v = v

-- | @x LIKE p@ (SPEC 2.3): NULL if either is NULL, else 1 or 0.
likeOp :: Value -> Value -> Value
likeOp a p
  | a == VNull || p == VNull = VNull
  | otherwise = fromBool (Just (likeMatch Nothing (textForm p) (textForm a)))

-- | @x LIKE p ESCAPE e@ (SPEC 7.3). The escape check comes before the NULL checks;
-- it is thrown as 'SqlFailure' because row functions are pure.
likeEscapeOp :: Value -> Value -> Value -> Value
likeEscapeOp a p e
  | e /= VNull, [_] <- textForm e = go
  | e /= VNull = throw (SqlFailure escapeNotSingleChar)
  | otherwise = VNull
  where
    go
      | a == VNull || p == VNull = VNull
      | otherwise = fromBool (Just (likeMatch (Just (head (textForm e))) (textForm p) (textForm a)))

-- | @x GLOB p@ (SPEC 7.2): NULL if either is NULL, else 1 or 0 on the text forms.
globOp :: Value -> Value -> Value
globOp a p
  | a == VNull || p == VNull = VNull
  | otherwise = fromBool (Just (maybe False (`matchTokens` textForm a) (globTokens (textForm p))))

-- | One element of a compiled pattern.
data PatTok
  = PStar -- ^ any sequence of characters
  | POne (Char -> Bool) -- ^ exactly one character satisfying the test

-- | Whole-text match of a LIKE pattern (ignoring ASCII case), with an optional
-- escape character. A trailing escape makes the pattern match nothing.
likeMatch :: Maybe Char -> String -> String -> Bool
likeMatch esc pat = maybe (const False) matchTokens (tokens pat)
  where
    tokens [] = Just []
    tokens (c : rest)
      | Just c == esc = case rest of
          [] -> Nothing
          d : rest' -> (literal d :) <$> tokens rest'
      | c == '%' = (PStar :) <$> tokens rest
      | c == '_' = (POne (const True) :) <$> tokens rest
      | otherwise = (literal c :) <$> tokens rest
    literal d = POne (\c -> asciiLower [c] == asciiLower [d])

-- | Compile a GLOB pattern; Nothing when it can match nothing (an unclosed @[@).
globTokens :: String -> Maybe [PatTok]
globTokens [] = Just []
globTokens (c : rest) = case c of
  '*' -> (PStar :) <$> globTokens rest
  '?' -> (POne (const True) :) <$> globTokens rest
  '[' -> do
    let (negated, body) = case rest of
          '^' : r -> (True, r)
          _ -> (False, rest)
    -- a leading ']' is a member, not the end
    (ranges, after) <- classBody (case body of ']' : r -> Just r; _ -> Nothing) body
    let inSet x = any (\(lo, hi) -> lo <= x && x <= hi) ranges
    (POne (\x -> inSet x /= negated) :) <$> globTokens after
  _ -> (POne (== c) :) <$> globTokens rest
  where
    classBody leading body = case leading of
      Just r -> do
        (rs, after) <- classMembers r
        Just ((']', ']') : rs, after)
      Nothing -> classMembers body
    -- members up to the closing ']'; "x-y" is a range unless the '-' is last
    classMembers s = case s of
      [] -> Nothing
      ']' : r -> Just ([], r)
      x : '-' : y : r | y /= ']' -> addMember (x, y) r
      x : r -> addMember (x, x) r
    addMember m r = do
      (rs, after) <- classMembers r
      Just (m : rs, after)

-- | Whole-text match of a token list. Simulates the pattern as an automaton over
-- its positions, so it cannot blow up.
matchTokens :: [PatTok] -> String -> Bool
matchTokens toks = final . foldl step (close (IntSet.singleton 0))
  where
    n = length toks
    arr = listArray (0, n - 1) toks :: Array Int PatTok
    isStar i = case arr ! i of PStar -> True; _ -> False
    close s = IntSet.foldr extend s s
    extend i acc
      | i < n && isStar i = IntSet.union acc (close (IntSet.singleton (i + 1)))
      | otherwise = acc
    step states c = close (IntSet.fromList
      [ case arr ! i of PStar -> i; POne _ -> i + 1
      | i <- IntSet.toList states, i < n, accepts (arr ! i) c ])
    accepts PStar _ = True
    accepts (POne ok) c = ok c
    final states = IntSet.member n states

-- | @CAST(x AS type)@ (SPEC 2.3).
castValue :: ColType -> Value -> Value
castValue _ VNull = VNull
castValue CText v = VText (textForm v)
castValue CInteger v = case v of
  VInt _ -> v
  VReal d -> VInt (clampInt (truncate d))
  VText s -> VInt (clampInt (integerPrefix (dropWhile (`elem` " \t\n\r") s)))
castValue CReal v = case v of
  VInt i -> VReal (fromIntegral i)
  VReal _ -> v
  VText s -> case numericPrefix s of
    VInt i -> VReal (fromIntegral i)
    other -> other

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
