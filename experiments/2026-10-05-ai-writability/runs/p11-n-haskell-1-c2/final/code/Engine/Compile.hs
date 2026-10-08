-- | Expression compilation: turns an 'Expr' into a function of a row
-- environment, reporting every name error up front, before any row is read
-- (SPEC 1.7, 4.2, 4.3).
module Engine.Compile
  ( module Engine.Scope
  , compileExpr
  ) where

import Control.Monad (when)
import Engine.Aggregate (AggCall (..), asAggregate)
import Engine.Error
import Engine.Functions (resolveFunction)
import Engine.Window (isWindowOnlyName, windowCalls)
import Engine.Operators (binaryOp, castValue, convertToAffinity, likeOp, unaryOp)
import Engine.Scope
import Engine.Syntax
import Engine.Value

-- | Compile an expression; also returns the affinity of a plain column reference.
compileExpr :: Scope -> Expr -> Result (Maybe ColType, RowFn)
compileExpr sc = go
  where
    go e | Just call <- asAggregate e = aggregateSlot e (acName call)
    go (EAggregate n _ _ _) = Left (noSuchFunction n)
    go (ELit v) = Right (Nothing, const v)
    go (EColumn q n) = column q n
    go (EUnary op e) = do
      (_, f) <- go e
      let g = unaryOp op
      Right (Nothing, g . f)
    go (EBinary op a b) = do
      let comparing = op `elem` [Eq, Ne, Lt, Le, Gt, Ge, Is, IsNot]
          nullTest = op `elem` [Is, IsNot] && (a == ELit VNull || b == ELit VNull)
          operand = if comparing && not nullTest then operandOf else go
      (ta, fa) <- operand a
      (tb, fb) <- operand b
      let g = binaryOp op ta tb
      Right (Nothing, \env -> g (fa env) (fb env))
    go e@(EWindow name _ _) = case scopeWindows sc of
      WindowSlots slots | Just i <- lookup e slots -> Right (Nothing, \env -> case env of row : _ -> row !! i; [] -> VNull)
      _ -> Left (misuseOfWindow name)
    go (ECall name _) | isWindowOnlyName name = Left (misuseOfWindow name)
    go (ECall name args) = do
      impl <- resolveFunction name (length args)
      fs <- mapM (fmap snd . go) args
      Right (Nothing, \env -> impl (map ($ env) fs))
    go (ECase operand branches other) = do
      subject <- traverse operandOf operand
      pairs <- mapM (\(c, r) -> (,) <$> go c <*> (snd <$> go r)) branches
      elseFn <- traverse (fmap snd . go) other
      let test env ((tc, fc), _) = case subject of
            Nothing -> truthValue (fc env) == Just True
            Just (ts, fs) -> binaryOp Eq ts tc (fs env) (fc env) == VInt 1
          pick env = case filter (test env) pairs of
            (_, res) : _ -> res env
            [] -> maybe VNull ($ env) elseFn
      Right (Nothing, pick)
    go (EBetween neg x lo hi) = do
      (tx, fx) <- operandOf x
      (tl, fl) <- operandOf lo
      (th, fh) <- operandOf hi
      let inRange env =
            binaryOp And Nothing Nothing
              (binaryOp Ge tx tl (fx env) (fl env))
              (binaryOp Le tx th (fx env) (fh env))
      Right (Nothing, negateIf neg . inRange)
    go (EIn neg x es) = do
      (tx, fx) <- go x
      fs <- mapM (fmap snd . go) es
      let convert = maybe id convertToAffinity tx
          member env =
            let v = fx env
                items = map (convert . ($ env)) fs
             in if null items then VInt 0
                else if v /= VNull && any (\i -> i /= VNull && compareValues v i == EQ) items then VInt 1
                else if v == VNull || VNull `elem` items then VNull
                else VInt 0
      Right (Nothing, negateIf neg . member)
    go (ELike neg x p) = do
      (_, fx) <- go x
      (_, fp) <- go p
      Right (Nothing, \env -> negateIf neg (likeOp (fx env) (fp env)))
    go (ECast e t) = do
      (_, f) <- go e
      Right (if t == CBlob then Nothing else Just t, castValue t . f)
    go (ESubquery sel) = scalarSubquery False sel
    go (EExists sel) = do
      sub <- scopeSubquery sc sc sel
      Right (Nothing, \env -> fromBool (Just (not (null (subRows sub env)))))
    go (EInSelect neg x sel) = do
      (tx, fx) <- go x
      sub <- scopeSubquery sc sc sel
      when (subWidth sub /= 1) (Left (subSelectColumns (subWidth sub)))
      let equal = binaryOp Eq tx (subAffinity sub)
          member env =
            let v = fx env
                results = [equal v i | [i] <- subRows sub env]
             in if null results then VInt 0
                else if VInt 1 `elem` results then VInt 1
                else if VNull `elem` results then VNull
                else VInt 0
      Right (Nothing, negateIf neg . member)

    -- A direct operand of a comparison, BETWEEN or CASE: a subquery of several columns is a row value.
    operandOf (ESubquery sel) = scalarSubquery True sel
    operandOf e = go e

    scalarSubquery isOperand sel = do
      sub <- scopeSubquery sc sc sel
      when (subWidth sub /= 1) $
        Left (if isOperand then rowValueMisused else subSelectColumns (subWidth sub))
      let first env = case subRows sub env of
            (v : _) : _ -> v
            _ -> VNull
      Right (subAffinity sub, first)

    aggregateSlot e name = case scopeAggs sc of
      NoAggregates direct _ -> Left (direct name)
      AggregateSlots slots -> case lookup e slots of
        Just i -> Right (Nothing, \env -> case env of row : _ -> row !! i; [] -> VNull)
        Nothing -> Left (misuseOfAggregate name)

    column q n = do
      found <- resolveName sc q n
      case found of
        Slot depth i affinity -> Right (affinity, \env -> (env !! depth) !! i)
        ViaAlias _ level e
          | not (null (windowCalls e)), NoWindows <- scopeWindows level -> Left (misuseOfAliasedWindow n)
        ViaAlias depth level e -> do
          let level' = level {scopeAliases = [], scopeAggs = viaAlias (scopeAggs level)}
          (_, f) <- compileExpr level' e
          Right (Nothing, f . drop depth)

    viaAlias (NoAggregates _ alias) = NoAggregates alias alias
    viaAlias slots = slots

    negateIf neg v = if neg then unaryOp Not v else v
