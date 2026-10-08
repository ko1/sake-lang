-- | The FROM clause (SPEC 4.1): its sources, and the rows of the joins between them.
module Engine.From
  ( FromPlan(..)
  , noFrom
  , compileFrom
  ) where

import Control.Monad (foldM)
import Data.Foldable (toList)
import Data.Maybe (fromMaybe)
import Engine.Ast
import Engine.Catalog
import Engine.Coerce (truthOf)
import Engine.Expr
import Engine.Names (foldName)
import Engine.Scope
import Engine.Value

-- | The sources of a FROM clause and a function from the rows of the enclosing queries to the joined rows.
-- Each row is the columns of all sources, in order.
data FromPlan = FromPlan
  { fpSources :: [Source]
  , fpRows :: Env -> Either String [[Value]]
  }

-- | No FROM: no sources and one empty row.
noFrom :: FromPlan
noFrom = FromPlan [] (const (Right [[]]))

-- | @compileFrom db binder outer clause@: @outer@ is the scope of the enclosing query, which ON can see;
-- a subquery in FROM cannot.
compileFrom :: Database -> SelectBinder -> Maybe Scope -> FromClause -> Either String FromPlan
compileFrom db binder outer (FromClause first joins) =
  fromItem db binder first >>= \start -> foldM (joinWith binder outer db) start joins

fromItem :: Database -> SelectBinder -> FromItem -> Either String FromPlan
fromItem db _ (FromTable name alias) = case lookupTable name db of
  Nothing -> Left ("no such table: " ++ name)
  Just t -> Right (FromPlan [tableSource (fromMaybe name alias) t] (const (Right (toList (tableRows t)))))
fromItem _ binder (FromSelect sel alias) = do
  sq <- binder Nothing sel
  let rows = sqRun sq []   -- not correlated: computed once
  Right (FromPlan [Source alias (sqColumns sq)] (const rows))

joinWith :: SelectBinder -> Maybe Scope -> Database -> FromPlan -> Join -> Either String FromPlan
joinWith binder outer db left (Join kind item constraint) = do
  right <- fromItem db binder item
  let leftSources = fpSources left
      rightWidth = sum (map sourceWidth (fpSources right))
      joined = newScope binder outer (leftSources ++ fpSources right)
  (cond, rightSources) <- case constraint of
    NoConstraint -> Right (Nothing, fpSources right)
    On e -> (\b -> (Just b, fpSources right)) <$> bindExpr joined e
    Using names -> usingCondition leftSources (fpSources right) names
  let rows env = do
        ls <- fpRows left env
        rs <- fpRows right env
        let matches l = [ row | r <- rs, let row = l ++ r, maybe True (holds env row) cond ]
            extend l = case (kind, matches l) of
              (JoinLeft, []) -> [l ++ replicate rightWidth VNull]
              (_, ms) -> ms
        Right (concatMap extend ls)
  Right (FromPlan (leftSources ++ rightSources) rows)
  where holds env row c = truthOf (evalExpr (row : env) c) == Just True

-- | USING (c, ...) is "left.c = right.c AND ..."; the right side's copy of each c is then hidden from
-- bare names and from '*'.
usingCondition :: [Source] -> [Source] -> [String] -> Either String (Maybe Bound, [Source])
usingCondition leftSources rightSources names = do
  equalities <- traverse equality names
  Right (Just (foldr1 (BBinary And) equalities), map hide rightSources)
  where
    leftWidth = sum (map sourceWidth leftSources)
    equality c = case (findSourceColumn leftSources c, findSourceColumn rightSources c) of
      (Just (i, lc), Just (j, rc)) -> Right (BBinary Eq (BCol i (scAffinity lc)) (BCol (leftWidth + j) (scAffinity rc)))
      _ -> Left ("cannot join using column " ++ c ++ " - column not present in both tables")
    hide s = s { srcColumns = [ if any (sameName (scName c)) names then c { scHidden = True } else c | c <- srcColumns s ] }
    sameName a b = foldName a == foldName b
