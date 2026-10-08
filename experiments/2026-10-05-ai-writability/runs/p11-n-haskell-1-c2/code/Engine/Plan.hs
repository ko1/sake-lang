-- | What planning a query produces ('Plan') and what it plans against ('Ctx'):
-- the database and the WITH tables in force (SPEC 5.2).
module Engine.Plan
  ( Plan (..)
  , Named
  , Ctx (..)
  , planIn
  , withColumnNames
  ) where

import Engine.Catalog (Database, Row)
import Engine.Error (Result)
import Engine.Scope
import Engine.Syntax
import Engine.Value (Value)

-- | A planned query: its result columns and a way to run it, given the rows of
-- the enclosing queries (for a correlated subquery).
data Plan = Plan
  { planColumns :: [ScopeColumn]
  , planRun :: Env -> Result [[Value]]
  }

-- | A named source other than a table (a WITH table): columns and rows. Lazy,
-- so that one that is never used is never planned.
type Named = Result ([ScopeColumn], [Row])

data Ctx = Ctx
  { ctxDb :: Database
  , ctxCtes :: [(String, Named)] -- ^ by 'identKey', innermost WITH first
  , ctxPlanQuery :: Ctx -> Maybe Scope -> Query -> Result Plan
    -- ^ planning of a full query, supplied by "Engine.Query" (which imports the select planner)
  }

-- | Plan a query in a context, inside an optional enclosing scope.
planIn :: Ctx -> Maybe Scope -> Query -> Result Plan
planIn ctx = ctxPlanQuery ctx ctx

-- | Rename the leading columns by an optional list of names (a view's or a cte's column list).
withColumnNames :: Maybe [Ident] -> [ScopeColumn] -> [ScopeColumn]
withColumnNames Nothing cols = cols
withColumnNames (Just names) cols = zipWith (\c n -> c {scName = n}) cols names ++ drop (length names) cols
