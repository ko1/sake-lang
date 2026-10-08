-- | Runtime values: their types, text form, numeric reading, the order of
-- values, and conversion when stored into a typed column (SPEC 1.3, 1.5, 1.9, 1.10).
module Engine.Value
  ( Value (..)
  , ColType (..)
  , colTypeName
  , valueTypeName
  , textForm
  , printForm
  , byteForm
  , hexOfBytes
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
  | VBlob String -- ^ one 'Char' (0..255) per byte; equality is by bytes
  deriving (Eq, Show)

-- | Declared column types.
data ColType = CInteger | CReal | CText | CBlob
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName CInteger = "INTEGER"
colTypeName CReal = "REAL"
colTypeName CText = "TEXT"
colTypeName CBlob = "BLOB"

-- | Upper-case type name used in storage errors (SPEC 7.4: an INTEGER value is @INT@ there).
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INT"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"
valueTypeName (VBlob _) = "BLOB"

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
textForm (VBlob s) = s -- the bytes read as characters (SPEC 7.1)

-- | How a result value is printed (SPEC 1.3, 7.1): a BLOB as @X'..'@, anything else as its text form.
printForm :: Value -> String
printForm (VBlob s) = "X'" ++ hexOfBytes s ++ "'"
printForm v = textForm v

-- | Two uppercase hexadecimal digits per byte.
hexOfBytes :: String -> String
hexOfBytes = concatMap byte
  where
    byte c = [digit (ord c `div` 16), digit (ord c `mod` 16)]
    digit n = "0123456789ABCDEF" !! n

-- | The bytes of a value's text form (a BLOB's own bytes), one 'Char' per byte; text is UTF-8 encoded.
byteForm :: Value -> String
byteForm (VBlob s) = s
byteForm v = concatMap utf8 (textForm v)
  where
    utf8 c
      | n < 0x80 = [c]
      | n < 0x800 = map chr [0xC0 + n `div` 64, 0x80 + n `mod` 64]
      | n < 0x10000 = map chr [0xE0 + n `div` 4096, 0x80 + (n `div` 64) `mod` 64, 0x80 + n `mod` 64]
      | otherwise =
          map chr [0xF0 + n `div` 262144, 0x80 + (n `div` 4096) `mod` 64, 0x80 + (n `div` 64) `mod` 64, 0x80 + n `mod` 64]
      where
        n = ord c

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
truthValue (VBlob s) = truthValue (numericPrefix s)

fromBool :: Maybe Bool -> Value
fromBool Nothing = VNull
fromBool (Just True) = VInt 1
fromBool (Just False) = VInt 0

-- | The order of values: NULL < numbers < text < blobs; numbers by value, text and blobs bytewise.
compareValues :: Value -> Value -> Ordering
compareValues a b = case (a, b) of
  (VInt x, VInt y) -> compare x y
  (VText x, VText y) -> compare x y
  (VBlob x, VBlob y) -> compare x y
  _ | rank a /= rank b -> compare (rank a) (rank b)
  (VNull, VNull) -> EQ
  _ -> compare (toRational' a) (toRational' b)
  where
    rank :: Value -> Int
    rank VNull = 0
    rank (VText _) = 2
    rank (VBlob _) = 3
    rank _ = 1
    toRational' (VInt i) = toRational i
    toRational' (VReal d) = toRational d
    toRational' _ = 0

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
    VBlob _ -> Left (valueTypeName v)
    _ -> Right (VText (textForm v))
  CBlob -> case v of
    VBlob _ -> Right v
    _ -> Left (valueTypeName v)
  where
    -- only TEXT is parsed as a number; a BLOB is never converted (SPEC 7.3, 7.4)
    v = case (ct, v0) of
      (CText, _) -> v0
      (CBlob, _) -> v0
      (_, VText s) -> fromMaybe v0 (parseNumericLiteral s)
      _ -> v0
    wholeInt64 d =
      d >= -9223372036854775808 && d < 9223372036854775808 && d == fromInteger (truncate d)
