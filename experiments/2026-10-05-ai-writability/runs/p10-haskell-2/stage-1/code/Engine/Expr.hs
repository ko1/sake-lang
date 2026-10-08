-- | Expressions in two steps: 'bindExpr' resolves names and functions against a scope
-- (so every name error happens before any row is read), 'evalExpr' computes a value for a row.
module Engine.Expr
  ( Bound(..)
  , Column(..)
  , Scope(..)
  , emptyScope
  , bindExpr
  , evalExpr
  ) where

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

-- | What names can mean: columns of the FROM table, then (where allowed) result-column aliases.
data Scope = Scope
  { scopeColumns :: [Column]
  , scopeAliases :: [(String, Bound)]   -- folded alias, its expression
  }

emptyScope :: Scope
emptyScope = Scope [] []

bindExpr :: Scope -> Expr -> Either String Bound
bindExpr _ (ELit v) = Right (BLit v)
bindExpr sc (EName n) =
  case findIndex ((== foldName n) . foldName . colName) (scopeColumns sc) of
    Just i -> Right (BCol i (colType (scopeColumns sc !! i)))
    Nothing -> maybe (Left ("no such column: " ++ n)) Right (lookup (foldName n) (scopeAliases sc))
bindExpr sc (ECall name args) = case lookupFunction (foldName name) of
  Nothing -> Left ("no such function: " ++ name)
  Just fn
    | arityAccepts (fnArity fn) (length args) -> BCall fn <$> traverse (bindExpr sc) args
    | otherwise -> Left ("wrong number of arguments to function " ++ name ++ "()")
bindExpr sc (EUnary op e) = BUnary op <$> bindExpr sc e
bindExpr sc (EBinary op a b) = BBinary op <$> bindExpr sc a <*> bindExpr sc b

evalExpr :: [Value] -> Bound -> Value
evalExpr _ (BLit v) = v
evalExpr row (BCol i _) = row !! i
evalExpr row (BCall fn args) = fnImpl fn (map (evalExpr row) args)
evalExpr row (BUnary op e) = unaryOp op (evalExpr row e)
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

-- | Only a bare column reference has an affinity.
affinityOf :: Bound -> Maybe ColType
affinityOf (BCol _ t) = Just t
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
