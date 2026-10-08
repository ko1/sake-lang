-- | Name resolution: turns an 'Expr' into a function of a row, reporting
-- every name error up front, before any row is read (SPEC 1.7).
module Engine.Compile
  ( Scope (..)
  , noRowScope
  , RowFn
  , compileExpr
  ) where

import Data.List (findIndex)
import Engine.Catalog (Column (..), Row)
import Engine.Error
import Engine.Functions (resolveFunction)
import Engine.Operators (binaryOp, castValue, convertToAffinity, likeOp, unaryOp)
import Engine.Syntax
import Engine.Value

-- | What names mean: the columns of the table in scope, and result-column
-- aliases usable as names (they stand for their expression).
data Scope = Scope
  { scopeTable :: Maybe Ident
  , scopeColumns :: [Column]
  , scopeAliases :: [(Ident, Expr)]
  }

-- | No table: any column name is an error.
noRowScope :: Scope
noRowScope = Scope Nothing [] []

type RowFn = Row -> Value

-- | Compile an expression; also returns the affinity of a plain column reference.
compileExpr :: Scope -> Expr -> Result (Maybe ColType, RowFn)
compileExpr sc = go
  where
    go (ELit v) = Right (Nothing, const v)
    go (EColumn q n) = column q n
    go (EUnary op e) = do
      (_, f) <- go e
      let g = unaryOp op
      Right (Nothing, g . f)
    go (EBinary op a b) = do
      (ta, fa) <- go a
      (tb, fb) <- go b
      let g = binaryOp op ta tb
      Right (Nothing, \r -> g (fa r) (fb r))
    go (ECall name args) = do
      impl <- resolveFunction name (length args)
      fs <- mapM (fmap snd . go) args
      Right (Nothing, \r -> impl (map ($ r) fs))
    go (ECase operand branches other) = do
      subject <- traverse go operand
      pairs <- mapM (\(c, r) -> (,) <$> go c <*> (snd <$> go r)) branches
      elseFn <- traverse (fmap snd . go) other
      let test r ((tc, fc), _) = case subject of
            Nothing -> truthValue (fc r) == Just True
            Just (ts, fs) -> binaryOp Eq ts tc (fs r) (fc r) == VInt 1
          pick r = case filter (test r) pairs of
            (_, res) : _ -> res r
            [] -> maybe VNull ($ r) elseFn
      Right (Nothing, pick)
    go (EBetween neg x lo hi) = do
      (tx, fx) <- go x
      (tl, fl) <- go lo
      (th, fh) <- go hi
      let inRange r =
            binaryOp And Nothing Nothing
              (binaryOp Ge tx tl (fx r) (fl r))
              (binaryOp Le tx th (fx r) (fh r))
      Right (Nothing, negateIf neg . inRange)
    go (EIn neg x es) = do
      (tx, fx) <- go x
      fs <- mapM (fmap snd . go) es
      let convert = maybe id convertToAffinity tx
          member r =
            let v = fx r
                items = map (convert . ($ r)) fs
             in if null items then VInt 0
                else if v /= VNull && any (\i -> i /= VNull && compareValues v i == EQ) items then VInt 1
                else if v == VNull || VNull `elem` items then VNull
                else VInt 0
      Right (Nothing, negateIf neg . member)
    go (ELike neg x p) = do
      (_, fx) <- go x
      (_, fp) <- go p
      Right (Nothing, \r -> negateIf neg (likeOp (fx r) (fp r)))
    go (ECast e t) = do
      (_, f) <- go e
      Right (Just t, castValue t . f)

    column q n =
      case findIndex matches (scopeColumns sc) of
        Just i | qualifierOk q ->
          Right (Just (columnType (scopeColumns sc !! i)), (!! i))
        _ -> case (q, lookup (identKey n) [(identKey a, e) | (a, e) <- scopeAliases sc]) of
          (Nothing, Just e) -> compileExpr sc {scopeAliases = []} e
          _ -> Left (noSuchColumn (maybe n (\t -> t ++ "." ++ n) q))
      where
        matches c = identKey (columnName c) == identKey n

    negateIf neg v = if neg then unaryOp Not v else v

    qualifierOk Nothing = True
    qualifierOk (Just t) = fmap identKey (scopeTable sc) == Just (identKey t)
