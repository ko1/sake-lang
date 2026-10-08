-- | Turning text into numbers: literal scanning, numeric prefixes and truth values (SPEC 1.2, 1.5, 1.8, 1.10).
module Engine.Coerce
  ( scanNumber
  , parseNumberText
  , numericPrefix
  , toNumber
  , truthOf
  , castValue
  ) where

import Data.Char (isDigit)
import Data.Maybe (fromMaybe)
import Engine.Value

isWs :: Char -> Bool
isWs c = c == ' ' || c == '\t' || c == '\n' || c == '\r'

-- | Scan an optionally signed numeric literal at the start of the string.
-- Returns the number (VInt or VReal) and the rest of the input.
scanNumber :: String -> Maybe (Value, String)
scanNumber s0 =
  if null intPart && null fracPart then Nothing else Just (value, rest)
  where
    (neg, s1) = case s0 of
      '-' : r -> (True, r)
      '+' : r -> (False, r)
      _ -> (False, s0)
    (intPart, s2) = span isDigit s1
    (fracPart, hasDot, s3) = case s2 of
      '.' : r -> let (f, r') = span isDigit r in (f, True, r')
      _ -> ("", False, s2)
    (expo, rest) = scanExponent s3
    digits = intPart ++ fracPart
    mantissa = if null digits then 0 else read digits :: Integer
    value
      | not hasDot && expo == Nothing =
          let n = if neg then negate mantissa else mantissa
          in if n >= toInteger (minBound :: Int) && n <= toInteger (maxBound :: Int)
               then VInt (fromInteger n)
               else VReal (fromRational (toRational n))
      | otherwise =
          let ex = max (-1000) (min 1000 (fromMaybe 0 expo))
              d = fromRational (toRational mantissa * 10 ^^ (ex - length fracPart)) :: Double
          in VReal (if neg then negate d else d)

-- | An exponent counts only when it has digits.
scanExponent :: String -> (Maybe Int, String)
scanExponent s = case s of
  c : r | c == 'e' || c == 'E' ->
    let (neg, r1) = case r of
          '-' : t -> (True, t)
          '+' : t -> (False, t)
          _ -> (False, r)
        (ds, r2) = span isDigit r1
    in if null ds then (Nothing, s)
       else (Just (let v = fromInteger (min 100000 (read ds)) in if neg then negate v else v), r2)
  _ -> (Nothing, s)

-- | The whole text (trimmed) as a number, if it is a numeric literal.
parseNumberText :: String -> Maybe Value
parseNumberText s = case scanNumber (dropWhile isWs s) of
  Just (v, rest) | all isWs rest -> Just v
  _ -> Nothing

-- | Read a TEXT value by numeric prefix; no prefix gives INTEGER 0.
numericPrefix :: String -> Value
numericPrefix s = case scanNumber (dropWhile isWs s) of
  Just (v, _) -> v
  Nothing -> VInt 0

-- | A non-NULL value as a number (VInt or VReal).
toNumber :: Value -> Value
toNumber (VText s) = numericPrefix s
toNumber (VBlob s) = numericPrefix s
toNumber v = v

-- | Truth value of a value; Nothing is unknown.
truthOf :: Value -> Maybe Bool
truthOf VNull = Nothing
truthOf (VInt n) = Just (n /= 0)
truthOf (VReal d) = Just (d /= 0)
truthOf (VText s) = truthOf (numericPrefix s)
truthOf (VBlob s) = truthOf (numericPrefix s)

-- | CAST(v AS type) (SPEC 2.3); NULL stays NULL.
castValue :: ColType -> Value -> Value
castValue _ VNull = VNull
castValue TBlob v@(VBlob _) = v
castValue TBlob (VText s) = VBlob (utf8Bytes s)
castValue TBlob v = VBlob (textForm v)
castValue TText v = VText (textForm v)
castValue TReal v = case toNumber v of
  VInt n -> VReal (fromIntegral n)
  other -> other
castValue TInteger v = case v of
  VInt _ -> v
  VReal d -> VInt (clampInt (truncate d))
  _ -> VInt (clampInt (integerPrefix (textForm v)))
  where
    clampInt :: Integer -> Int
    clampInt n = fromInteger (max (toInteger (minBound :: Int)) (min (toInteger (maxBound :: Int)) n))

-- | Optional sign and digits at the start (after whitespace); 0 when there are none.
integerPrefix :: String -> Integer
integerPrefix s0 = case dropWhile isWs s0 of
  '-' : r -> negate (digitsOf r)
  '+' : r -> digitsOf r
  r -> digitsOf r
  where
    digitsOf r = case span isDigit r of
      ([], _) -> 0
      (ds, _) -> read ds
