-- | Printing of REAL values (SPEC 1.3): C's printf("%.15g") plus the ".0" adjustments.
module Engine.Real
  ( formatReal
  ) where

-- | The text form of a REAL.
formatReal :: Double -> String
formatReal x
  | x == 0 = "0.0"                 -- also negative zero
  | x < 0 = '-' : addPoint (formatG15 (negate x))
  | otherwise = addPoint (formatG15 x)

-- | No '.' and no 'e' gets ".0"; an 'e' without '.' gets ".0" before the 'e'.
addPoint :: String -> String
addPoint s
  | '.' `elem` s = s
  | otherwise = case break (== 'e') s of
      (m, []) -> m ++ ".0"
      (m, ex) -> m ++ ".0" ++ ex

-- | %.15g of a positive finite double, computed exactly (round-half-even on the exact value).
formatG15 :: Double -> String
formatG15 x
  | e < -4 || e >= precision = expForm
  | e >= 0 = fixedBig
  | otherwise = "0." ++ replicate (negate e - 1) '0' ++ sig
  where
    precision = 15 :: Int
    r = toRational x
    e0 = decimalExponent r
    n0 = round (r / (10 ^^ (e0 - precision + 1))) :: Integer
    -- rounding may carry into a new digit (9.99..9 -> 10.0..0)
    (n, e) | n0 >= 10 ^ precision = (n0 `div` 10, e0 + 1)
           | otherwise = (n0, e0)
    allDigits = show n
    sig = case reverse (dropWhile (== '0') (reverse allDigits)) of
      [] -> "0"
      ds -> ds
    expForm = case sig of
      [d] -> d : expSuffix
      d : ds -> d : '.' : ds ++ expSuffix
      [] -> expSuffix
    expSuffix = 'e' : (if e < 0 then '-' else '+') : pad2 (show (abs e))
    pad2 t = replicate (2 - length t) '0' ++ t
    fixedBig =
      let padded = sig ++ replicate (e + 1 - length sig) '0'
          (ip, fp) = splitAt (e + 1) padded
      in if null fp then ip else ip ++ "." ++ fp

-- | The e with 10^e <= r < 10^(e+1).
decimalExponent :: Rational -> Int
decimalExponent r = go (floor (logBase 10 (fromRational r :: Double)))
  where
    go e | r < 10 ^^ e = go (e - 1)
         | r >= 10 ^^ (e + 1) = go (e + 1)
         | otherwise = e
