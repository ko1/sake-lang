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
import Engine.Operators (binaryOp, unaryOp)
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

    column q n =
      case findIndex matches (scopeColumns sc) of
        Just i | qualifierOk q ->
          Right (Just (columnType (scopeColumns sc !! i)), (!! i))
        _ -> case (q, lookup (identKey n) [(identKey a, e) | (a, e) <- scopeAliases sc]) of
          (Nothing, Just e) -> compileExpr sc {scopeAliases = []} e
          _ -> Left (noSuchColumn (maybe n (\t -> t ++ "." ++ n) q))
      where
        matches c = identKey (columnName c) == identKey n

    qualifierOk Nothing = True
    qualifierOk (Just t) = fmap identKey (scopeTable sc) == Just (identKey t)
