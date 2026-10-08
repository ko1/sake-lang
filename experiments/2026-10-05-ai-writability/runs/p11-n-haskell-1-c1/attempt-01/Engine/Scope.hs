-- | What names mean (SPEC 4.2): the sources of a query, the queries that
-- enclose it, result-column aliases, and how a name is resolved to a position
-- in the row of some enclosing level.
--
-- Rows are evaluated against an 'Env': the current query's row first, then
-- the row of each enclosing query, innermost first. A row holds the columns
-- of all the query's sources, side by side in source order.
module Engine.Scope
  ( Env
  , RowFn
  , ScopeColumn (..)
  , Source (..)
  , sourceWidth
  , sourcesWidth
  , Scope (..)
  , AggContext (..)
  , WindowContext (..)
  , Subquery (..)
  , SubqueryCompiler
  , newScope
  , rootScope
  , Resolved (..)
  , resolveName
  , exprCollation
  , scopeColumnCollation
  ) where

import Data.List (findIndex)
import Engine.Catalog (Row)
import Engine.Error
import Engine.Syntax
import Engine.Value (ColType, CollInfo (..), Value, collationByName, infoCollation, Collation (..))

-- | The rows a function reads: this level's row, then the enclosing levels'.
type Env = [Row]

type RowFn = Env -> Value


-- | A column visible through a source.
data ScopeColumn = ScopeColumn
  { scName :: Ident
  , scAffinity :: Maybe ColType -- ^ the type of the column it was read from, if any (SPEC 1.9)
  , scCollation :: Maybe CollInfo -- ^ the collation of the expression it was read from, if it has one (SPEC 7.3, 7.5)
  , scMerged :: Bool -- ^ the right side's copy of a @USING@ column: found only by @q.c@
  }

-- | One from-item. A subquery without an alias has no name.
data Source = Source
  { sourceName :: Maybe Ident
  , sourceColumns :: [ScopeColumn]
  }

sourceWidth :: Source -> Int
sourceWidth = length . sourceColumns

sourcesWidth :: [Source] -> Int
sourcesWidth = sum . map sourceWidth

-- | What an aggregate call means where it is written (SPEC 3.3).
data AggContext
  = NoAggregates (String -> SqlError) (String -> SqlError)
    -- ^ an error, given the call's name: written directly / reached through an alias
  | AggregateSlots [(Expr, Int)]
    -- ^ the call's value is already in the row at this index (see "Engine.Grouping")

-- | What a window call means where it is written (SPEC 6.2).
data WindowContext
  = NoWindows -- ^ a window call here is misuse
  | WindowSlots [(Expr, Int)]
    -- ^ the call's value is already in the row at this index (see "Engine.WindowPlan")

-- | A compiled subquery: the number of its result columns, the affinity of
-- the first one, and its rows given the row environment of the place it is written.
data Subquery = Subquery
  { subWidth :: Int
  , subAffinity :: Maybe ColType
  , subCollation :: Maybe CollInfo -- ^ the collation of the first result column's expression
  , subRows :: Env -> [[Value]]
  }

-- | Compile a subquery written in the given scope (supplied by "Engine.Select",
-- which this module cannot import).
type SubqueryCompiler = Scope -> Query -> Result Subquery

data Scope = Scope
  { scopeSources :: [Source]
  , scopeAliases :: [(Ident, Expr)] -- ^ result-column aliases usable as names; they stand for their expression
  , scopeAggs :: AggContext
  , scopeWindows :: WindowContext
  , scopeOuter :: [Scope] -- ^ the enclosing queries' scopes, innermost first
  , scopeSubquery :: SubqueryCompiler
  }

-- | The scope of a query with the given sources, inside an optional enclosing scope.
-- Aggregate calls are misuse until the caller says otherwise.
newScope :: SubqueryCompiler -> Maybe Scope -> [Source] -> Scope
newScope compile parent sources =
  Scope sources [] (NoAggregates misuseOfAggregate misuseOfAggregateAlias) NoWindows
    (maybe [] (\p -> p : scopeOuter p) parent) compile

-- | A scope with no sources and nothing around it (INSERT values, LIMIT).
rootScope :: SubqueryCompiler -> Scope
rootScope compile = newScope compile Nothing []

-- | Where a name lives.
data Resolved
  = Slot Int Int (Maybe ColType) Collation -- ^ levels up, position in that level's row, affinity, collation
  | ViaAlias Int Scope Expr -- ^ a result alias of the scope that many levels up

-- | Resolve @[q.]c@ (SPEC 4.2).
resolveName :: Scope -> Maybe Ident -> Ident -> Result Resolved
resolveName sc qualifier name = search 0 (sc : scopeOuter sc)
  where
    same a b = identKey a == identKey b
    placed lvl = zip (scanl (+) 0 (map sourceWidth (scopeSources lvl))) (scopeSources lvl)
    search _ [] = Left (noSuchColumn (maybe name (\q -> q ++ "." ++ name) qualifier))
    search d (lvl : rest) = case qualifier of
      Just q -> case [(o, s) | (o, s) <- placed lvl, fmap identKey (sourceName s) == Just (identKey q)] of
        [] -> search (d + 1) rest
        (o, s) : _ -> case findIndex (same name . scName) (sourceColumns s) of
          Just j -> Right (let c = sourceColumns s !! j in Slot d (o + j) (scAffinity c) (scopeColumnCollation c))
          Nothing -> Left (noSuchColumn (q ++ "." ++ name)) -- the innermost level with a source q decides
      Nothing ->
        case [ (o + j, c)
             | (o, s) <- placed lvl, (j, c) <- zip [0 ..] (sourceColumns s)
             , not (scMerged c), same name (scName c) ] of
          [(i, c)] -> Right (Slot d i (scAffinity c) (scopeColumnCollation c))
          _ : _ : _ -> Left (ambiguousColumn name)
          [] -> case lookup (identKey name) [(identKey a, e) | (a, e) <- scopeAliases lvl] of
            Just e -> Right (ViaAlias d lvl e)
            Nothing -> search (d + 1) rest

-- | The collation a column has when it is referenced: implicit, BINARY if its source expression had none (SPEC 7.5).
scopeColumnCollation :: ScopeColumn -> Collation
scopeColumnCollation = maybe Binary infoCollation . scCollation

-- | The collation of an expression (SPEC 7.3). An unknown name in COLLATE is an error.
exprCollation :: Scope -> Expr -> Result (Maybe CollInfo)
exprCollation sc e = case e of
  ECollate _ n -> case collationByName n of
    Just c -> Right (Just (Explicit c))
    Nothing -> Left (noSuchCollation n)
  EColumn q n -> do
    found <- resolveName sc q n
    case found of
      Slot _ _ _ c -> Right (Just (Implicit c))
      ViaAlias _ level x -> exprCollation level {scopeAliases = []} x
  EUnary Pos x -> exprCollation sc x
  ECast x _ -> exprCollation sc x
  _ -> Right Nothing
