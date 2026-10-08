-- | Expressions in two steps: 'bindExpr' resolves names and functions against a scope
-- (so every name error happens before any row is read), 'evalExpr' computes a value for a row.
module Engine.Expr
  ( Bound(..)
  , Column(..)
  , Scope(..)
  , emptyScope
  , tableScope
  , bindExpr
  , evalExpr
  ) where

import Data.Char (toLower)
import Data.List (findIndex)
import Data.Maybe (fromMaybe)
import Engine.Ast
import Engine.Coerce
import Engine.Functions
import Engine.Names (foldName)
import Engine.Value

data Column = Column { colName :: String, colType :: ColType }
  deriving (Show)

-- | An expression whose names are resolved: columns are row positions, functions are looked up.
data Bound
  = BLit Value
  | BCol Int ColType
  | BUnary UnOp Bound
  | BBinary BinOp Bound Bound
  | BCall Function [Bound]
  | BCase (Maybe Bound) [(Bound, Bound)] (Maybe Bound)
  | BBetween Bool Bound Bound Bound
  | BIn Bool Bound [Bound]
  | BLike Bool Bound Bound
  | BCast Bound ColType
  | BSlot Int                 -- a value computed per group (an aggregate), placed after the row's columns

-- | What names can mean: columns of the FROM table, then (where allowed) result-column aliases.
data Scope = Scope
  { scopeColumns :: [Column]
  , scopeAliases :: [(String, Either String Bound)]   -- folded alias; its expression, or the error using it raises
  , scopeAggBase :: Int                               -- where the group's aggregate values start in the row
  , scopeAggMisuse :: String -> String                -- error for an aggregate call here (not allowed)
  }

-- | Only the columns; an aggregate call is misuse (WHERE, UPDATE, ...).
tableScope :: [Column] -> Scope
tableScope cols = Scope cols [] (length cols) (\n -> "misuse of aggregate function " ++ n ++ "()")

emptyScope :: Scope
emptyScope = tableScope []

bindExpr :: Scope -> Expr -> Either String Bound
bindExpr _ (ELit v) = Right (BLit v)
bindExpr sc (EName n) =
  case findIndex ((== foldName n) . foldName . colName) (scopeColumns sc) of
    Just i -> Right (BCol i (colType (scopeColumns sc !! i)))
    Nothing -> fromMaybe (Left ("no such column: " ++ n)) (lookup (foldName n) (scopeAliases sc))
bindExpr sc (ECall name args)
  | isAggregateCall (foldName name) (length args) = Left (scopeAggMisuse sc name)
  | otherwise = case lookupFunction (foldName name) of
      Nothing -> Left ("no such function: " ++ name)
      Just fn
        | arityAccepts (fnArity fn) (length args) -> BCall fn <$> traverse (bindExpr sc) args
        | otherwise -> Left ("wrong number of arguments to function " ++ name ++ "()")
bindExpr sc (EAggCall c) = Left (scopeAggMisuse sc (acName c))
bindExpr sc (EAggRef k) = Right (BSlot (scopeAggBase sc + k))
bindExpr sc (EUnary op e) = BUnary op <$> bindExpr sc e
bindExpr sc (EBinary op a b) = BBinary op <$> bindExpr sc a <*> bindExpr sc b
bindExpr sc (ECase operand branches els) =
  BCase <$> traverse (bindExpr sc) operand
        <*> traverse (\(w, t) -> (,) <$> bindExpr sc w <*> bindExpr sc t) branches
        <*> traverse (bindExpr sc) els
bindExpr sc (EBetween neg x lo hi) = BBetween neg <$> bindExpr sc x <*> bindExpr sc lo <*> bindExpr sc hi
bindExpr sc (EIn neg x items) = BIn neg <$> bindExpr sc x <*> traverse (bindExpr sc) items
bindExpr sc (ELike neg x p) = BLike neg <$> bindExpr sc x <*> bindExpr sc p
bindExpr sc (ECast e t) = (`BCast` t) <$> bindExpr sc e

evalExpr :: [Value] -> Bound -> Value
evalExpr _ (BLit v) = v
evalExpr row (BCol i _) = row !! i
evalExpr row (BSlot i) = row !! i
evalExpr row (BCall fn args) = fnImpl fn (map (evalExpr row) args)
evalExpr row (BUnary op e) = unaryOp op (evalExpr row e)
evalExpr row (BCast e t) = castValue t (evalExpr row e)
evalExpr row (BCase operand branches els) = pick branches
  where
    base = fmap (\o -> (evalExpr row o, affinityOf o)) operand
    pick [] = maybe VNull (evalExpr row) els
    pick ((w, t) : rest)
      | matches w = evalExpr row t
      | otherwise = pick rest
    matches w = case base of
      Nothing -> truthOf (evalExpr row w) == Just True
      Just (v, aff) -> truthOf (compareOp Eq aff (affinityOf w) v (evalExpr row w)) == Just True
evalExpr row (BBetween neg x lo hi) = negateIf neg (logicOp And (truthOf ge) (truthOf le))
  where
    vx = evalExpr row x
    ge = compareOp Ge (affinityOf x) (affinityOf lo) vx (evalExpr row lo)
    le = compareOp Le (affinityOf x) (affinityOf hi) vx (evalExpr row hi)
evalExpr row (BIn neg x items) = negateIf neg result
  where
    vx = evalExpr row x
    aff = affinityOf x
    vs = map (convertTo aff . evalExpr row) items
    result
      | isNull vx = VNull
      | any ((== EQ) . compareValues vx) (filter (not . isNull) vs) = VInt 1
      | any isNull vs = VNull
      | otherwise = VInt 0
evalExpr row (BLike neg x p) = negateIf neg $ case (evalExpr row x, evalExpr row p) of
  (VNull, _) -> VNull
  (_, VNull) -> VNull
  (a, b) -> fromTruth (Just (likeMatch (textForm b) (textForm a)))
evalExpr row (BBinary op a b)
  | op == And || op == Or = logicOp op (truthOf va) (truthOf vb)
  | isArith op = arith op va vb
  | op == Concat = concatValues va vb
  | otherwise = compareOp op (affinityOf a) (affinityOf b) va vb
  where
    va = evalExpr row a
    vb = evalExpr row b

isArith :: BinOp -> Bool
isArith op = op `elem` [Add, Sub, Mul, Div, Mod]

negateIf :: Bool -> Value -> Value
negateIf True v = unaryOp Not v
negateIf False v = v

-- | LIKE: '%' any run, '_' one character, other characters equal ignoring ASCII case.
-- Tracks the set of pattern positions reachable so far, so it never backtracks.
likeMatch :: String -> String -> Bool
likeMatch pat = go (closure [0])
  where
    n = length pat
    closure = foldr add []
      where add i acc | i `elem` acc = acc
                      | i < n && pat !! i == '%' = add (i + 1) (i : acc)
                      | otherwise = i : acc
    go states [] = n `elem` states
    go states (c : cs)
      | null states = False
      | otherwise = go (closure (concatMap (step c) states)) cs
    step c i
      | i >= n = []
      | pat !! i == '%' = [i]
      | pat !! i == '_' = [i + 1]
      | lowerAscii (pat !! i) == lowerAscii c = [i + 1]
      | otherwise = []
    lowerAscii c = if isAsciiUpper' c then toLower c else c
    isAsciiUpper' c = c >= 'A' && c <= 'Z'

-- | Convert a value to an affinity (for the list of IN); no affinity changes nothing.
convertTo :: Maybe ColType -> Value -> Value
convertTo (Just TText) v@(VInt _) = VText (textForm v)
convertTo (Just TText) v@(VReal _) = VText (textForm v)
convertTo (Just _) v@(VText s) = fromMaybe v (parseNumberText s)
convertTo _ v = v

-- Unary and logic -------------------------------------------------------------

unaryOp :: UnOp -> Value -> Value
unaryOp Plus v = v
unaryOp Not v = fromTruth (not <$> truthOf v)
unaryOp Neg VNull = VNull
unaryOp Neg v = case toNumber v of
  VInt n -> VInt (negate n)
  VReal d -> VReal (negate d)
  other -> other

fromTruth :: Maybe Bool -> Value
fromTruth Nothing = VNull
fromTruth (Just b) = VInt (if b then 1 else 0)

-- | Three-valued AND / OR.
logicOp :: BinOp -> Maybe Bool -> Maybe Bool -> Value
logicOp And a b = fromTruth $ case (a, b) of
  (Just False, _) -> Just False
  (_, Just False) -> Just False
  (Just True, Just True) -> Just True
  _ -> Nothing
logicOp _ a b = fromTruth $ case (a, b) of
  (Just True, _) -> Just True
  (_, Just True) -> Just True
  (Just False, Just False) -> Just False
  _ -> Nothing

-- Arithmetic and concatenation -------------------------------------------------

arith :: BinOp -> Value -> Value -> Value
arith _ VNull _ = VNull
arith _ _ VNull = VNull
arith op a b = case (toNumber a, toNumber b) of
  (VInt x, VInt y) -> intArith op x y
  (x, y) -> realArith op (asDouble x) (asDouble y)

asDouble :: Value -> Double
asDouble (VInt n) = fromIntegral n
asDouble (VReal d) = d
asDouble _ = 0

-- | y == -1 is special-cased so minBound never traps.
intArith :: BinOp -> Int -> Int -> Value
intArith Add x y = VInt (x + y)
intArith Sub x y = VInt (x - y)
intArith Mul x y = VInt (x * y)
intArith Div x y
  | y == 0 = VNull
  | y == -1 = VInt (negate x)
  | otherwise = VInt (x `quot` y)
intArith _ x y
  | y == 0 = VNull
  | y == -1 = VInt 0
  | otherwise = VInt (x `rem` y)

realArith :: BinOp -> Double -> Double -> Value
realArith Add x y = VReal (x + y)
realArith Sub x y = VReal (x - y)
realArith Mul x y = VReal (x * y)
realArith Div x y
  | y == 0 = VNull
  | otherwise = VReal (x / y)
realArith _ x y
  | yi == 0 = VNull
  | otherwise = VReal (fromIntegral (xi `rem` yi))
  where
    xi = truncate x :: Integer
    yi = truncate y :: Integer

concatValues :: Value -> Value -> Value
concatValues VNull _ = VNull
concatValues _ VNull = VNull
concatValues a b = VText (textForm a ++ textForm b)

-- Comparison and affinity (SPEC 1.9) ---------------------------------------------

-- | Only a column reference or a CAST has an affinity.
affinityOf :: Bound -> Maybe ColType
affinityOf (BCol _ t) = Just t
affinityOf (BCast _ t) = Just t
affinityOf _ = Nothing

compareOp :: BinOp -> Maybe ColType -> Maybe ColType -> Value -> Value -> Value
compareOp op affA affB a b
  | op == Is = fromTruth (Just (isSame))
  | op == IsNot = fromTruth (Just (not isSame))
  | isNull a || isNull b = VNull
  | otherwise = fromTruth (Just (test (compareValues a' b')))
  where
    (a', b') = applyAffinity affA affB a b
    isSame
      | isNull a || isNull b = isNull a && isNull b
      | otherwise = compareValues a' b' == EQ
    test o = case op of
      Eq -> o == EQ
      Ne -> o /= EQ
      Lt -> o == LT
      Le -> o /= GT
      Gt -> o == GT
      _ -> o /= LT

applyAffinity :: Maybe ColType -> Maybe ColType -> Value -> Value -> (Value, Value)
applyAffinity affA affB a b
  | numeric affA && textOrNone affB = (a, numberIfText b)
  | numeric affB && textOrNone affA = (numberIfText a, b)
  | affA == Just TText && affB == Nothing = (a, textIfNumber b)
  | affB == Just TText && affA == Nothing = (textIfNumber a, b)
  | otherwise = (a, b)
  where
    numeric t = t == Just TInteger || t == Just TReal
    textOrNone t = t == Nothing || t == Just TText
    numberIfText v@(VText s) = fromMaybe v (parseNumberText s)
    numberIfText v = v
    textIfNumber v@(VInt _) = VText (textForm v)
    textIfNumber v@(VReal _) = VText (textForm v)
    textIfNumber v = v
