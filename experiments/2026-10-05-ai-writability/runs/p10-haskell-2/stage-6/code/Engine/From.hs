-- | The FROM clause (SPEC 4.1, 5.2, 5.3): its sources (tables, views, ctes, subqueries), and the rows of the joins between them.
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

-- | @compileFrom db binderFor outer clause@: @outer@ is the scope of the enclosing query, which ON can see;
-- a subquery in FROM cannot. @binderFor@ compiles a select in a given database (a view's select runs
-- without the statement's ctes).
compileFrom :: Database -> (Database -> SelectBinder) -> Maybe Scope -> FromClause -> Either String FromPlan
compileFrom db binderFor outer (FromClause first joins) =
  fromItem db binderFor first >>= \start -> foldM (joinWith (binderFor db) outer db binderFor) start joins

-- | A name in FROM is a cte (which hides tables and views), else a table, else a view.
fromItem :: Database -> (Database -> SelectBinder) -> FromItem -> Either String FromPlan
fromItem db binderFor (FromTable name alias) = case lookupCte name db of
  Just found -> found >>= Right . subquerySource
  Nothing -> case (lookupTable name db, lookupView name db) of
    (Just t, _) -> Right (FromPlan [tableSource label t] (const (Right (toList (tableRows t)))))
    (_, Just v) -> viewSource v >>= Right . subquerySource
    _ -> Left ("no such table: " ++ name)
  where
    label = fromMaybe name alias
    subquerySource sq = FromPlan [Source (Just label) (sqColumns sq)] (sqRun sq)
    viewSource v = do
      sq <- binderFor (withoutCtes db) Nothing (viewSelect v)
      cachedRows <$> withColumnNames (\listed _ -> viewMismatch v listed (length (sqColumns sq))) (viewColumns v) sq
    viewMismatch v listed got = "expected " ++ show listed ++ " columns for '" ++ viewName v ++ "' but got " ++ show got
fromItem db binderFor (FromSelect sel alias) = do
  sq <- cachedRows <$> binderFor db Nothing sel   -- not correlated: computed once
  Right (FromPlan [Source alias (sqColumns sq)] (sqRun sq))

joinWith :: SelectBinder -> Maybe Scope -> Database -> (Database -> SelectBinder) -> FromPlan -> Join -> Either String FromPlan
joinWith binder outer db binderFor left (Join kind item constraint) = do
  right <- fromItem db binderFor item
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
