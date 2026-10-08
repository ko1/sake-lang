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
  , rowidColumn
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
  ) where

import Data.List (findIndex)
import Engine.Catalog (Row)
import Engine.Error
import Engine.Syntax
import Engine.Value (ColType (..), Value)

-- | The rows a function reads: this level's row, then the enclosing levels'.
type Env = [Row]

type RowFn = Env -> Value


-- | A column visible through a source.
data ScopeColumn = ScopeColumn
  { scName :: Ident
  , scAffinity :: Maybe ColType -- ^ the type of the column it was read from, if any (SPEC 1.9)
  , scMerged :: Bool -- ^ the right side's copy of a @USING@ column: found only by @q.c@
  , scRowid :: Bool -- ^ a table's rowid (the last value of its rows): found only by a rowid name, never by @*@
  }

-- | The rowid column a table source carries after its real columns (SPEC 7.1).
rowidColumn :: ScopeColumn
rowidColumn = ScopeColumn "rowid" (Just CInteger) False True

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
  = Slot Int Int (Maybe ColType) -- ^ levels up, position in that level's row, affinity
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
        (o, s) : _ -> case columnOf s of
          Just j -> Right (Slot d (o + j) (scAffinity (sourceColumns s !! j)))
          Nothing -> Left (noSuchColumn (q ++ "." ++ name)) -- the innermost level with a source q decides
      Nothing ->
        case [ (o + j, scAffinity c)
             | (o, s) <- placed lvl, (j, c) <- zip [0 ..] (sourceColumns s)
             , not (scMerged c), not (scRowid c), same name (scName c) ] of
          [(i, a)] -> Right (Slot d i a)
          _ : _ : _ -> Left (ambiguousColumn name)
          [] -> case rowidSlots lvl of
            [i] | length (scopeSources lvl) == 1 -> Right (Slot d i (Just CInteger))
            _ : _ -> Left (ambiguousColumn name) -- a rowid name with several sources (SPEC 7.1)
            [] -> case lookup (identKey name) [(identKey a, e) | (a, e) <- scopeAliases lvl] of
              Just e -> Right (ViaAlias d lvl e)
              Nothing -> search (d + 1) rest
    -- a real column wins over the rowid of the same source
    columnOf s =
      case findIndex (\c -> not (scRowid c) && same name (scName c)) (sourceColumns s) of
        Just j -> Just j
        Nothing | isRowidName name -> findIndex scRowid (sourceColumns s)
                | otherwise -> Nothing
    -- positions of the rowids of a level's table sources, when the name is a rowid name
    rowidSlots lvl
      | isRowidName name = [o + j | (o, s) <- placed lvl, (j, c) <- zip [0 ..] (sourceColumns s), scRowid c]
      | otherwise = []
