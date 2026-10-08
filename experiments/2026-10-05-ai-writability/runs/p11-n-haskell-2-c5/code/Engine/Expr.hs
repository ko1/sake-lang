-- | Expressions in two steps: 'bindExpr' resolves names, functions and subqueries against a scope
-- (so every name error happens before any row is read), 'evalExpr' computes a value for a row.
module Engine.Expr
  ( bindExpr
  , evalExpr
  , evalConstant
  , windowMisuse
  ) where

import Data.Char (toLower)
import Data.Maybe (fromMaybe)
import Engine.Ast
import Engine.Coerce
import Engine.Failure (failSql)
import Engine.Functions
import Engine.Names (foldName)
import Engine.Scope
import Engine.Value

bindExpr :: Scope -> Expr -> Either String Bound
bindExpr _ (ELit v) = Right (BLit v)
bindExpr sc (EName n) = resolveName sc Nothing n
bindExpr sc (EQualified q n) = resolveName sc (Just q) n
bindExpr sc (EColumnAt i) = case drop i (scopeColumns sc) of
  c : _ -> Right (BCol i (scAffinity c))
  [] -> Left "internal error: column position out of range"
bindExpr _ (EWindow c) = Left (windowMisuse (wcName c))
bindExpr sc (ECall name args)
  | isWindowOnlyName (foldName name) = Left (windowMisuse name)
  | isAggregateCall (foldName name) (length args) = Left (scopeAggMisuse sc name)
  | otherwise = case lookupFunction (foldName name) of
      Nothing -> Left ("no such function: " ++ name)
      Just fn
        | arityAccepts (fnArity fn) (length args) -> BCall fn <$> traverse (bindExpr sc) args
        | otherwise -> Left ("wrong number of arguments to function " ++ name ++ "()")
bindExpr sc (EAggCall c) = Left (scopeAggMisuse sc (acName c))
bindExpr sc (EAggRef k) = Right (BSlot (scopeWidth sc + k))
bindExpr sc (EUnary op e) = BUnary op <$> bindExpr sc e
bindExpr sc (EBinary op a b)
  | op `elem` [Eq, Ne, Lt, Le, Gt, Ge] = BBinary op <$> comparand a <*> comparand b
  | op `elem` [Is, IsNot] = BBinary op <$> comparandVs b a <*> comparandVs a b
  | otherwise = BBinary op <$> bindExpr sc a <*> bindExpr sc b
  where
    comparand = bindComparand sc
    -- "x IS NULL" is not a comparison of a subquery (SPEC 4.3)
    comparandVs other e = if other == ELit VNull then bindExpr sc e else bindComparand sc e
bindExpr sc (ECase operand branches els) =
  BCase <$> traverse (bindComparand sc) operand
        <*> traverse (\(w, t) -> (,) <$> bindExpr sc w <*> bindExpr sc t) branches
        <*> traverse (bindExpr sc) els
bindExpr sc (EBetween neg x lo hi) = BBetween neg <$> bindComparand sc x <*> bindComparand sc lo <*> bindComparand sc hi
bindExpr sc (EIn neg x items) = BIn neg <$> bindExpr sc x <*> traverse (bindExpr sc) items
bindExpr sc (ELike neg x p e) = BLike neg <$> bindExpr sc x <*> bindExpr sc p <*> traverse (bindExpr sc) e
bindExpr sc (EGlob neg x p) = BGlob neg <$> bindExpr sc x <*> bindExpr sc p
bindExpr sc (ECast e t) = (`BCast` t) <$> bindExpr sc e
bindExpr sc (ESubquery sel) = do
  sq <- subquery sc sel
  case sqColumns sq of
    [_] -> Right (BScalarSub sq)
    cols -> Left (columnCountError cols)
bindExpr sc (EExists sel) = BExists <$> subquery sc sel
bindExpr sc (EInSelect neg x sel) = do
  sq <- subquery sc sel
  case sqColumns sq of
    [_] -> BInSub neg <$> bindExpr sc x <*> pure sq
    cols -> Left (columnCountError cols)

-- | A window call (or a window-only function without OVER) where windows are not computed (SPEC 6.2).
windowMisuse :: String -> String
windowMisuse n = "misuse of window function " ++ n ++ "()"

subquery :: Scope -> Select -> Either String Subquery
subquery sc = scopeSelect sc (Just sc)

columnCountError :: [ScopeColumn] -> String
columnCountError cols = "sub-select returns " ++ show (length cols) ++ " columns - expected 1"

-- | An operand of a comparison, BETWEEN or CASE x: a subquery here may not be a row of several values.
bindComparand :: Scope -> Expr -> Either String Bound
bindComparand sc (ESubquery sel) = do
  sq <- subquery sc sel
  case sqColumns sq of
    [_] -> Right (BScalarSub sq)
    _ -> Left "row value misused"
bindComparand sc e = bindExpr sc e

-- | The value of a bound expression that names no column.
evalConstant :: Bound -> Value
evalConstant = evalExpr [[]]

-- | The row of the query being evaluated (the Env is never empty).
currentRow :: Env -> [Value]
currentRow (row : _) = row
currentRow [] = []

-- | Rows of a subquery. A failure while running it (only integer overflow in a sum) yields no rows.
subqueryRows :: Env -> Subquery -> [[Value]]
subqueryRows env sq = either (const []) id (sqRun sq env)

evalExpr :: Env -> Bound -> Value
evalExpr _ (BLit v) = v
evalExpr env (BCol i _) = currentRow env !! i
evalExpr env (BSlot i) = currentRow env !! i
evalExpr env (BShift n b) = evalExpr (drop n env) b
evalExpr env (BScalarSub sq) = case subqueryRows env sq of
  (v : _) : _ -> v
  _ -> VNull
evalExpr env (BExists sq) = VInt (if null (subqueryRows env sq) then 0 else 1)
evalExpr env (BInSub neg x sq) = negateIf neg result
  where
    vx = evalExpr env x
    vs = [ v | v : _ <- subqueryRows env sq ]
    equal v = truthOf (compareOp Eq (affinityOf x) (affinityOfSub sq) vx v) == Just True
    result
      | null vs = VInt 0
      | isNull vx = VNull
      | any equal vs = VInt 1
      | any isNull vs = VNull
      | otherwise = VInt 0
    affinityOfSub s = case sqColumns s of c : _ -> scAffinity c; [] -> Nothing
evalExpr env (BCall fn args) = fnImpl fn (map (evalExpr env) args)
evalExpr env (BUnary op e) = unaryOp op (evalExpr env e)
evalExpr env (BCast e t) = castValue t (evalExpr env e)
evalExpr env (BCase operand branches els) = pick branches
  where
    base = fmap (\o -> (evalExpr env o, affinityOf o)) operand
    pick [] = maybe VNull (evalExpr env) els
    pick ((w, t) : rest)
      | matches w = evalExpr env t
      | otherwise = pick rest
    matches w = case base of
      Nothing -> truthOf (evalExpr env w) == Just True
      Just (v, aff) -> truthOf (compareOp Eq aff (affinityOf w) v (evalExpr env w)) == Just True
evalExpr env (BBetween neg x lo hi) = negateIf neg (logicOp And (truthOf ge) (truthOf le))
  where
    vx = evalExpr env x
    ge = compareOp Ge (affinityOf x) (affinityOf lo) vx (evalExpr env lo)
    le = compareOp Le (affinityOf x) (affinityOf hi) vx (evalExpr env hi)
evalExpr env (BIn neg x items) = negateIf neg result
  where
    vx = evalExpr env x
    aff = affinityOf x
    vs = map (convertTo aff . evalExpr env) items
    result
      | isNull vx = VNull
      | any ((== EQ) . compareValues vx) (filter (not . isNull) vs) = VInt 1
      | any isNull vs = VNull
      | otherwise = VInt 0
evalExpr env (BLike neg x p esc) = negateIf neg (likeValue (evalExpr env x) (evalExpr env p) (fmap (evalExpr env) esc))
evalExpr env (BGlob neg x p) = negateIf neg $ case (evalExpr env x, evalExpr env p) of
  (VNull, _) -> VNull
  (_, VNull) -> VNull
  (a, b) -> fromTruth (Just (globMatch (textForm b) (textForm a)))
evalExpr env (BBinary op a b)
  | op == And || op == Or = logicOp op (truthOf va) (truthOf vb)
  | isArith op = arith op va vb
  | op == Concat = concatValues va vb
  | otherwise = compareOp op (affinityOf a) (affinityOf b) va vb
  where
    va = evalExpr env a
    vb = evalExpr env b

isArith :: BinOp -> Bool
isArith op = op `elem` [Add, Sub, Mul, Div, Mod]

negateIf :: Bool -> Value -> Value
negateIf True v = unaryOp Not v
negateIf False v = v

-- | x LIKE p [ESCAPE e]. A bad escape fails before the NULL checks (SPEC 7.3).
likeValue :: Value -> Value -> Maybe Value -> Value
likeValue vx vp Nothing = likeResult Nothing vx vp
likeValue _ _ (Just VNull) = VNull
likeValue vx vp (Just ve) = case textForm ve of
  [c] -> likeResult (Just c) vx vp
  _ -> failSql "ESCAPE expression must be a single character"

likeResult :: Maybe Char -> Value -> Value -> Value
likeResult _ VNull _ = VNull
likeResult _ _ VNull = VNull
likeResult esc a b = fromTruth (Just (likeMatch esc (textForm b) (textForm a)))

-- | One element of a LIKE pattern.
data LikePart = LikeRun | LikeOne | LikeChar Char

-- | The elements of a LIKE pattern; the escape character (if any) makes the next character ordinary.
-- Nothing when the pattern ends in an escape character: it matches nothing.
likeParts :: Maybe Char -> String -> Maybe [LikePart]
likeParts esc = go
  where
    go [] = Just []
    go (c : r)
      | Just c == esc = case r of
          [] -> Nothing
          d : r' -> (LikeChar d :) <$> go r'
      | c == '%' = (LikeRun :) <$> go r
      | c == '_' = (LikeOne :) <$> go r
      | otherwise = (LikeChar c :) <$> go r

-- | LIKE: '%' any run, '_' one character, other characters equal ignoring ASCII case.
likeMatch :: Maybe Char -> String -> String -> Bool
likeMatch esc pat s = case likeParts esc pat of
  Nothing -> False
  Just parts -> matchParts isRun one parts s
  where
    isRun LikeRun = True
    isRun _ = False
    one LikeOne _ = True
    one (LikeChar d) c = lowerAscii d == lowerAscii c
    one LikeRun _ = False
    lowerAscii c = if c >= 'A' && c <= 'Z' then toLower c else c

-- | One element of a GLOB pattern.
data GlobPart = GlobRun | GlobOne | GlobChar Char | GlobSet Bool [SetItem]   -- negated?, members

data SetItem = SetChar Char | SetRange Char Char

-- | The elements of a GLOB pattern (SPEC 7.2); Nothing when a '[' is never closed: nothing matches.
globParts :: String -> Maybe [GlobPart]
globParts [] = Just []
globParts ('*' : r) = (GlobRun :) <$> globParts r
globParts ('?' : r) = (GlobOne :) <$> globParts r
globParts ('[' : r) = case r3 of
  [] -> Nothing
  _ : rest -> (GlobSet neg (setItems (leading ++ body)) :) <$> globParts rest
  where
    (neg, r1) = case r of
      '^' : t -> (True, t)
      _ -> (False, r)
    (leading, r2) = case r1 of          -- a ']' right after '[' or '[^' is a member
      ']' : t -> ("]", t)
      _ -> ("", r1)
    (body, r3) = break (== ']') r2
globParts (c : r) = (GlobChar c :) <$> globParts r

-- | Members of a class: 'x-y' is a range; a first or last '-' is the character itself.
setItems :: String -> [SetItem]
setItems (a : '-' : b : rest) = SetRange a b : setItems rest
setItems (a : rest) = SetChar a : setItems rest
setItems [] = []

-- | GLOB: the pattern matches the whole text; ordinary characters are case-sensitive.
globMatch :: String -> String -> Bool
globMatch pat s = case globParts pat of
  Nothing -> False
  Just parts -> matchParts isRun one parts s
  where
    isRun GlobRun = True
    isRun _ = False
    one GlobOne _ = True
    one (GlobChar d) c = d == c
    one (GlobSet neg items) c = any (member c) items /= neg
    one GlobRun _ = False
    member c (SetChar d) = c == d
    member c (SetRange lo hi) = c >= lo && c <= hi

-- | Match a whole string against pattern elements, where run elements match any sequence.
-- Tracks the set of pattern positions reachable so far, so it never backtracks.
matchParts :: (p -> Bool) -> (p -> Char -> Bool) -> [p] -> String -> Bool
matchParts isRun one parts = go (closure [0])
  where
    n = length parts
    closure = foldr add []
      where add i acc | i `elem` acc = acc
                      | i < n && isRun (parts !! i) = add (i + 1) (i : acc)
                      | otherwise = i : acc
    go states [] = n `elem` states
    go states (c : cs)
      | null states = False
      | otherwise = go (closure (concatMap (step c) states)) cs
    step c i
      | i >= n = []
      | isRun (parts !! i) = [i]
      | one (parts !! i) c = [i + 1]
      | otherwise = []

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
