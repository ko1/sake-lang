-- | Built-in scalar functions (SPEC 1.11, 2.4).
module Engine.Functions (resolveFunction) where

import Data.Char (chr, ord)
import Data.List (intercalate, isPrefixOf, tails)
import Data.Maybe (fromMaybe)
import Engine.Error
import Engine.Syntax (Ident, identKey)
import Engine.Value

data Arity = Exactly Int | AtLeast Int | Between Int Int

-- | Look a function up by name and check the argument count.
resolveFunction :: Ident -> Int -> Result ([Value] -> Value)
resolveFunction name argc = do
  (arity, impl) <- lookup (identKey name) table `orElse` noSuchFunction name
  if accepts arity then Right impl else Left (wrongArgCount name)
  where
    accepts (Exactly n) = argc == n
    accepts (AtLeast n) = argc >= n
    accepts (Between lo hi) = argc >= lo && argc <= hi

table :: [(String, (Arity, [Value] -> Value))]
table =
  [ ("length", (Exactly 1, nullable1 (\v -> VInt (fromIntegral (length (textForm v))))))
  , ("upper", (Exactly 1, nullable1 (VText . asciiUpper . textForm)))
  , ("lower", (Exactly 1, nullable1 (VText . asciiLower . textForm)))
  , ("abs", (Exactly 1, nullable1 absolute))
  , ("typeof", (Exactly 1, typeOf))
  , ("coalesce", (AtLeast 2, coalesce))
  , ("ifnull", (Exactly 2, coalesce))
  , ("nullif", (Exactly 2, nullIf))
  , ("substr", (Between 2 3, nullIfAnyNull substr))
  , ("trim", (Between 1 2, nullIfAnyNull (trimWith True True)))
  , ("ltrim", (Between 1 2, nullIfAnyNull (trimWith True False)))
  , ("rtrim", (Between 1 2, nullIfAnyNull (trimWith False True)))
  , ("replace", (Exactly 3, nullIfAnyNull replaceAll))
  , ("instr", (Exactly 2, nullIfAnyNull instr))
  , ("round", (Between 1 2, nullIfAnyNull roundTo))
  , ("max", (AtLeast 2, extremum GT))
  , ("min", (AtLeast 2, extremum LT))
  , ("concat", (AtLeast 1, concatValues))
  , ("concat_ws", (AtLeast 2, concatWs))
  , ("char", (AtLeast 0, charFromCodes))
  , ("unicode", (Exactly 1, nullable1 firstCodePoint))
  , ("sign", (Exactly 1, nullable1 signOf))
  ]

-- | Wrap a function so that any NULL argument gives NULL.
nullIfAnyNull :: ([Value] -> Value) -> [Value] -> Value
nullIfAnyNull f args
  | VNull `elem` args = VNull
  | otherwise = f args

-- | An argument read as an integer (numeric prefix for text, truncating reals).
intArg :: Value -> Integer
intArg v = case v of
  VInt i -> toInteger i
  VReal d -> truncate d
  VText s -> intArg (numericPrefix s)
  VNull -> 0

-- | SPEC 2.4 substr, following the position rules step by step.
substr :: [Value] -> Value
substr (x : startV : rest) = VText (take (clampLen q2) (drop (clampLen p2) text))
  where
    text = textForm x
    len = toInteger (length text)
    p0 = intArg startV
    q0 = case rest of
      lenV : _ -> intArg lenV
      [] -> 10 ^ (30 :: Int)
    (p1, q1)
      | p0 < 0 =
          let p' = p0 + len
           in if p' < 0 then (0, max 0 (q0 + p')) else (p', q0)
      | p0 > 0 = (p0 - 1, q0)
      | otherwise = (0, if q0 > 0 then q0 - 1 else q0)
    (p2, q2)
      | q1 < 0 =
          let q' = negate q1
              p' = p1 - q'
           in if p' < 0 then (0, q' + p') else (p', q')
      | otherwise = (p1, q1)
    clampLen = fromInteger . max 0 . min (len + 1)
substr _ = VNull

trimWith :: Bool -> Bool -> [Value] -> Value
trimWith front back (x : rest) = VText (cutBack (cutFront (textForm x)))
  where
    chars = case rest of
      c : _ -> textForm c
      [] -> " "
    cutFront = if front then dropWhile (`elem` chars) else id
    cutBack = if back then reverse . dropWhile (`elem` chars) . reverse else id
trimWith _ _ [] = VNull

replaceAll :: [Value] -> Value
replaceAll [x, from, to]
  | null f = VText (textForm x)
  | otherwise = VText (go (textForm x))
  where
    f = textForm from
    t = textForm to
    go [] = []
    go s@(c : cs)
      | f `isPrefixOf` s = t ++ go (drop (length f) s)
      | otherwise = c : go cs
replaceAll _ = VNull

instr :: [Value] -> Value
instr [x, y] = VInt (go 1 (tails (textForm x)))
  where
    needle = textForm y
    go _ [] = if null needle then 1 else 0
    go i (s : more)
      | needle `isPrefixOf` s = i
      | otherwise = go (i + 1) more
instr _ = VNull

roundTo :: [Value] -> Value
roundTo (x : rest) = VReal (roundDecimal places d)
  where
    places = case rest of
      n : _ -> fromInteger (max 0 (min 400 (intArg n)))
      [] -> 0
    d = case x of
      VInt i -> fromIntegral i
      VReal r -> r
      VText s -> case numericPrefix s of
        VInt i -> fromIntegral i
        VReal r -> r
        _ -> 0
      VNull -> 0
roundTo [] = VNull

-- | max/min: NULL if any argument is NULL, else the extreme in the order of
-- values; among equals the first.
extremum :: Ordering -> [Value] -> Value
extremum want args
  | VNull `elem` args = VNull
  | otherwise = foldl1 pick args
  where
    pick best v = if compareValues v best == want then v else best

-- | A one-argument function that maps NULL to NULL.
nullable1 :: (Value -> Value) -> [Value] -> Value
nullable1 _ [VNull] = VNull
nullable1 f [v] = f v
nullable1 _ _ = VNull

typeOf :: [Value] -> Value
typeOf [v] = VText (typeName v)
typeOf _ = VNull

absolute :: Value -> Value
absolute (VInt i) = VInt (abs i)
absolute (VReal d) = VReal (abs d)
absolute (VText s) = case numericPrefix s of
  VInt i -> VReal (abs (fromIntegral i))
  VReal d -> VReal (abs d)
  _ -> VReal 0
absolute v = v

typeName :: Value -> String
typeName VNull = "null"
typeName (VInt _) = "integer"
typeName (VReal _) = "real"
typeName (VText _) = "text"

coalesce :: [Value] -> Value
coalesce args = fromMaybe VNull (lookupFirst args)
  where
    lookupFirst (v : vs) = if v /= VNull then Just v else lookupFirst vs
    lookupFirst [] = Nothing

-- | NULL if the arguments are equal in the order of values (no affinity), else the first.
nullIf :: [Value] -> Value
nullIf [x, y]
  | x /= VNull && y /= VNull && compareValues x y == EQ = VNull
  | otherwise = x
nullIf _ = VNull

-- | The text forms of the non-NULL values, in order.
presentTexts :: [Value] -> [String]
presentTexts vs = [textForm v | v <- vs, v /= VNull]

-- | NULL arguments are skipped; all NULL gives ''.
concatValues :: [Value] -> Value
concatValues = VText . concat . presentTexts

-- | A NULL separator gives NULL; NULL items are skipped with no separator.
concatWs :: [Value] -> Value
concatWs (VNull : _) = VNull
concatWs (sep : items) = VText (intercalate (textForm sep) (presentTexts items))
concatWs [] = VNull

-- | Each argument is a code point.
charFromCodes :: [Value] -> Value
charFromCodes = VText . map (chr . fromInteger . intArg)

-- | Code point of the first character of the text form; NULL if that is ''.
firstCodePoint :: Value -> Value
firstCodePoint v = case textForm v of
  c : _ -> VInt (fromIntegral (ord c))
  [] -> VNull

-- | -1, 0 or 1; TEXT counts only if it is a whole numeric literal (SPEC 1.5 step 2).
signOf :: Value -> Value
signOf v = case v of
  VInt i -> VInt (signum i)
  VReal d -> VInt (if d < 0 then -1 else if d > 0 then 1 else 0)
  VText s -> maybe VNull signOf (parseNumericLiteral s)
  VNull -> VNull
