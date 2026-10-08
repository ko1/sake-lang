-- | Runtime values: their types, text form, numeric reading, the order of
-- values, and conversion when stored into a typed column (SPEC 1.3, 1.5, 1.9, 1.10).
module Engine.Value
  ( Value (..)
  , ColType (..)
  , colTypeName
  , valueTypeName
  , textForm
  , formatReal
  , roundDecimal
  , asciiLower
  , asciiUpper
  , scanNumber
  , parseNumericLiteral
  , numericPrefix
  , truthValue
  , fromBool
  , compareValues
  , Collation (..)
  , collationByName
  , Collated (..)
  , ownCollation
  , pairCollation
  , asImplicit
  , compareValuesWith
  , compareRows
  , storeValue
  ) where

import Data.Char (chr, isDigit, ord)
import Data.Int (Int64)
import Data.List (dropWhileEnd)
import Data.Maybe (fromMaybe)

data Value
  = VNull
  | VInt Int64
  | VReal Double
  | VText String
  deriving (Eq, Show)

-- | Declared column types.
data ColType = CInteger | CReal | CText
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName CInteger = "INTEGER"
colTypeName CReal = "REAL"
colTypeName CText = "TEXT"

-- | Upper-case type name used in storage errors.
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INTEGER"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"

asciiLower, asciiUpper :: String -> String
asciiLower = map (\c -> if c >= 'A' && c <= 'Z' then chr (ord c + 32) else c)
asciiUpper = map (\c -> if c >= 'a' && c <= 'z' then chr (ord c - 32) else c)

isSqlSpace :: Char -> Bool
isSqlSpace c = c `elem` " \t\n\r"

-- | The printed form of a value; also its text form wherever a number becomes text.
textForm :: Value -> String
textForm VNull = "NULL"
textForm (VInt i) = show i
textForm (VReal d) = formatReal d
textForm (VText s) = s

-- | C's @printf("%.15g")@ plus the @.0@ fix-ups of SPEC 1.3. Rounds the exact
-- binary value (not the shortest decimal) so ties behave like C.
formatReal :: Double -> String
formatReal x
  | x == 0 = "0.0"
  | x < 0 = '-' : formatReal (negate x)
  | otherwise = digitsToString e ds
  where
    (e, ds) = roundTo15 (toRational x)

-- | Decimal exponent and the significant digits (trailing zeros stripped,
-- at least one digit) of a positive rational rounded to 15 digits.
roundTo15 :: Rational -> (Int, String)
roundTo15 r = (e, dropWhileEnd (== '0') (show n))
  where
    (e, n) = significantDigits 15 r

-- | @significantDigits k r@ for positive r: the decimal exponent e and the
-- k-digit integer n with r ~ n * 10^(e-k+1), rounded half to even like C.
significantDigits :: Int -> Rational -> (Int, Integer)
significantDigits k r = (e', n')
  where
    e0 = floor (logBase 10 (fromRational r :: Double)) :: Int
    p10 j = 10 ^^ j :: Rational
    e = until (\j -> p10 j <= r) (subtract 1) (until (\j -> p10 (j + 1) > r) (+ 1) e0)
    n = round (r / p10 (e - k + 1)) :: Integer
    (n', e') = if n >= 10 ^ k then (n `div` 10, e + 1) else (n, e)

-- | SPEC 2.4 @round@: round the 17-significant-digit decimal form of x to
-- @places@ digits after the point, halves away from zero.
roundDecimal :: Int -> Double -> Double
roundDecimal places x
  | x == 0 = 0
  | x < 0 = negate (roundDecimal places (negate x))
  | otherwise = fromRational (fromInteger (floor (decimal * scale + 1 / 2)) / scale)
  where
    (e, n) = significantDigits 17 (toRational x)
    decimal = fromInteger n * 10 ^^ (e - 16) :: Rational
    scale = 10 ^ places :: Rational

digitsToString :: Int -> String -> String
digitsToString e ds
  | e < -4 || e >= 15 = mantissa ++ "e" ++ (if e < 0 then "-" else "+") ++ pad2 (abs e)
  | e >= 0 =
      let padded = ds ++ replicate (e + 1 - length ds) '0'
          (ip, fp) = splitAt (e + 1) padded
       in ip ++ "." ++ (if null fp then "0" else fp)
  | otherwise = "0." ++ replicate (-e - 1) '0' ++ ds
  where
    mantissa = case ds of
      [d] -> [d, '.', '0']
      (d : rest) -> d : '.' : rest
      [] -> "0.0"
    pad2 k = let s = show k in if length s < 2 then '0' : s else s

-- | Read an optional sign and the longest numeric literal at the start of the
-- string: digits with optional fraction and exponent, or @.@ digits.
-- Returns the number and the unread rest. An exponent counts only with digits.
scanNumber :: String -> Maybe (Value, String)
scanNumber s0
  | null ip && null fp = Nothing
  | not hasDot && null ex = Just (intValue, s4)
  | otherwise = Just (VReal (applySign (read realText)), s4)
  where
    (neg, s1) = case s0 of
      '-' : r -> (True, r)
      '+' : r -> (False, r)
      _ -> (False, s0)
    (ip, s2) = span isDigit s1
    (hasDot, fp, s3) = case s2 of
      '.' : r -> let (f, r') = span isDigit r in (True, f, r')
      _ -> (False, "", s2)
    (ex, s4) = scanExponent s3
    applySign :: Double -> Double
    applySign d = if neg then negate d else d
    intValue =
      let i = (if neg then negate else id) (read ip :: Integer)
       in if i >= fromIntegral (minBound :: Int64) && i <= fromIntegral (maxBound :: Int64)
            then VInt (fromInteger i)
            else VReal (fromInteger i)
    realText =
      (if null ip then "0" else ip) ++ "." ++ (if null fp then "0" else fp)
        ++ (if null ex then "" else "e" ++ ex)

-- | An exponent @e[+-]digits@ as a signed digit string (clamped), and the rest.
scanExponent :: String -> (String, String)
scanExponent (c : rest)
  | c `elem` "eE" =
      let (sgn, r1) = case rest of
            '-' : r -> ("-", r)
            '+' : r -> ("", r)
            _ -> ("", rest)
          (ds, r2) = span isDigit r1
       in if null ds then ("", c : rest) else (sgn ++ clamp ds, r2)
  where
    clamp ds = show (min 5000 (read ds :: Integer))
scanExponent s = ("", s)

-- | SPEC 1.5 step 2: the whole text (trimmed) is a numeric literal.
parseNumericLiteral :: String -> Maybe Value
parseNumericLiteral s = case scanNumber (trim s) of
  Just (v, "") -> Just v
  _ -> Nothing
  where
    trim = dropWhileEnd isSqlSpace . dropWhile isSqlSpace

-- | Read a text as a number by numeric prefix (SPEC 1.8); no prefix gives INTEGER 0.
numericPrefix :: String -> Value
numericPrefix s = maybe (VInt 0) fst (scanNumber (dropWhile isSqlSpace s))

-- | Truth value of SPEC 1.10: 'Nothing' is unknown.
truthValue :: Value -> Maybe Bool
truthValue VNull = Nothing
truthValue (VInt i) = Just (i /= 0)
truthValue (VReal d) = Just (d /= 0)
truthValue (VText s) = truthValue (numericPrefix s)

fromBool :: Maybe Bool -> Value
fromBool Nothing = VNull
fromBool (Just True) = VInt 1
fromBool (Just False) = VInt 0

-- | The order of values: NULL < numbers < text; numbers by value, text bytewise.
compareValues :: Value -> Value -> Ordering
compareValues a b = case (a, b) of
  (VInt x, VInt y) -> compare x y
  (VText x, VText y) -> compare x y
  _ | rank a /= rank b -> compare (rank a) (rank b)
  (VNull, VNull) -> EQ
  _ -> compare (toRational' a) (toRational' b)
  where
    rank :: Value -> Int
    rank VNull = 0
    rank (VText _) = 2
    rank _ = 1
    toRational' (VInt i) = toRational i
    toRational' (VReal d) = toRational d
    toRational' _ = 0

-- | The rules for comparing two TEXT values (collations).
data Collation = Binary | NoCase | RTrim
  deriving (Eq, Show)

-- | A collation by its name, matched case-insensitively.
collationByName :: String -> Maybe Collation
collationByName n = lookup (asciiLower n) [("binary", Binary), ("nocase", NoCase), ("rtrim", RTrim)]

-- | The collation an expression has: none, one it inherits from a column
-- (implicit), or one given by @COLLATE@ (explicit).
data Collated = NoCollation | Implicit Collation | Explicit Collation
  deriving (Eq, Show)

-- | The collation the values of one expression are compared under among themselves.
ownCollation :: Collated -> Collation
ownCollation NoCollation = Binary
ownCollation (Implicit c) = c
ownCollation (Explicit c) = c

-- | The collation of @a op b@: an explicit one (a before b), else an implicit one (a before b), else BINARY.
pairCollation :: Collated -> Collated -> Collation
pairCollation a b = case [c | Explicit c <- [a, b]] ++ [c | Implicit c <- [a, b]] of
  c : _ -> c
  [] -> Binary

-- | How a result column's collation shows when it becomes a column of a source (SPEC 7.5):
-- always implicit, BINARY when it had none.
asImplicit :: Collated -> Collated
asImplicit NoCollation = Implicit Binary
asImplicit (Explicit c) = Implicit c
asImplicit i = i

-- | 'compareValues' with TEXT against TEXT compared under a collation.
compareValuesWith :: Collation -> Value -> Value -> Ordering
compareValuesWith coll a b = case (a, b) of
  (VText x, VText y) -> case coll of
    Binary -> compare x y
    NoCase -> compare (asciiLower x) (asciiLower y)
    RTrim -> compare (dropWhileEnd (== ' ') x) (dropWhileEnd (== ' ') y)
  _ -> compareValues a b

-- | Rows compared value by value, each under its own column's collation (BINARY past the list).
compareRows :: [Collation] -> [Value] -> [Value] -> Ordering
compareRows colls as bs = mconcat (zipWith3 compareValuesWith (colls ++ repeat Binary) as bs)

-- | Convert a value for storage in a column; 'Left' carries the name of the
-- type that was rejected (SPEC 1.5).
storeValue :: ColType -> Value -> Either String Value
storeValue _ VNull = Right VNull
storeValue ct v0 = case ct of
  CInteger -> case v of
    VInt _ -> Right v
    VReal d | wholeInt64 d -> Right (VInt (truncate d))
    _ -> Left (valueTypeName v)
  CReal -> case v of
    VInt i -> Right (VReal (fromIntegral i))
    VReal _ -> Right v
    _ -> Left (valueTypeName v)
  CText -> case v of
    VText _ -> Right v
    _ -> Right (VText (textForm v))
  where
    v = case (ct, v0) of
      (CText, _) -> v0
      (_, VText s) -> fromMaybe v0 (parseNumericLiteral s)
      _ -> v0
    wholeInt64 d =
      d >= -9223372036854775808 && d < 9223372036854775808 && d == fromInteger (truncate d)
