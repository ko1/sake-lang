-- | Name resolution: what the names of a query can mean (SPEC 4.2), and the bound form of expressions.
--
-- A query's row is the concatenation of the columns of its sources, then (in an aggregate query) one
-- slot per aggregate. Subqueries see the rows of the queries around them as an 'Env': the head is the
-- query's own row, the rest are the enclosing queries' rows, innermost first.
module Engine.Scope
  ( Bound(..)
  , Env
  , ScopeColumn(..)
  , Source(..)
  , Scope(..)
  , Subquery(..)
  , SelectBinder
  , withColumnNames
  , cachedRows
  , newScope
  , scopeWidth
  , sourceWidth
  , scopeColumns
  , findSourceColumn
  , resolveName
  , affinityOf
  ) where

import Data.List (findIndex)
import Engine.Ast (BinOp, Select, UnOp)
import Engine.Functions (Function)
import Engine.Names (foldName)
import Engine.Value

-- | The rows of the queries around the one being evaluated, innermost first.
type Env = [[Value]]

-- | An expression whose names are resolved: columns are row positions, functions are looked up.
data Bound
  = BLit Value
  | BCol Int (Maybe ColType)   -- position in the current row, and the column's affinity
  | BShift Int Bound           -- evaluate on the enclosing queries' rows (drop n rows of the Env)
  | BUnary UnOp Bound
  | BBinary BinOp Bound Bound
  | BCall Function [Bound]
  | BCase (Maybe Bound) [(Bound, Bound)] (Maybe Bound)
  | BBetween Bool Bound Bound Bound
  | BIn Bool Bound [Bound]
  | BLike Bool Bound Bound
  | BCast Bound ColType
  | BSlot Int                  -- a value computed per group (an aggregate), placed after the row's columns
  | BScalarSub Subquery        -- first column of the first row, or NULL
  | BInSub Bool Bound Subquery -- negated?, x, single-column subquery
  | BExists Subquery

-- | A compiled SELECT: its result columns and a function from the enclosing rows to its rows.
data Subquery = Subquery
  { sqColumns :: [ScopeColumn]
  , sqRun :: Env -> Either String [[Value]]
  }

-- | A column as names see it. A column of a table has an affinity; so does a subquery column that
-- is a plain column reference.
data ScopeColumn = ScopeColumn
  { scName :: String
  , scAffinity :: Maybe ColType
  , scHidden :: Bool   -- the right side's copy of a USING column: not found by bare name, not in '*'
  }

-- | One item of a FROM clause. Its name is the alias, else the table's name; a subquery may have none.
data Source = Source
  { srcName :: Maybe String
  , srcColumns :: [ScopeColumn]
  }

-- | Name the columns of a view or cte by its column list (none written: unchanged); the affinity of
-- each column stays. The function builds the error for a list and a select of different widths.
withColumnNames :: (Int -> Int -> String) -> [String] -> Subquery -> Either String Subquery
withColumnNames _ [] sq = Right sq
withColumnNames mismatch names sq
  | length names /= length (sqColumns sq) = Left (mismatch (length names) (length (sqColumns sq)))
  | otherwise = Right sq { sqColumns = zipWith (\n c -> c { scName = n }) names (sqColumns sq) }

-- | A subquery that is not correlated: its rows are computed once, on first use.
cachedRows :: Subquery -> Subquery
cachedRows sq = sq { sqRun = const rows }
  where rows = sqRun sq []

-- | Compile a SELECT found inside an expression or a FROM, given the scope enclosing it (Nothing: none).
-- Supplied by Engine.Query, which this module and Engine.Expr cannot import.
type SelectBinder = Maybe Scope -> Select -> Either String Subquery

-- | The names in force in one clause of one query.
data Scope = Scope
  { scopeSources :: [Source]
  , scopeAliases :: [(String, Either String Bound)]   -- folded alias; its expression, or the error using it raises
  , scopeAggMisuse :: String -> String                -- error for an aggregate call here (not allowed)
  , scopeOuter :: Maybe Scope                         -- the query this one is a subquery of
  , scopeSelect :: SelectBinder
  }

-- | Sources only: no aliases, an aggregate call is misuse (WHERE, ON, UPDATE, ...).
newScope :: SelectBinder -> Maybe Scope -> [Source] -> Scope
newScope binder outer sources = Scope
  { scopeSources = sources
  , scopeAliases = []
  , scopeAggMisuse = \n -> "misuse of aggregate function " ++ n ++ "()"
  , scopeOuter = outer
  , scopeSelect = binder
  }

sourceWidth :: Source -> Int
sourceWidth = length . srcColumns

-- | Number of columns of the row (the aggregate slots start here).
scopeWidth :: Scope -> Int
scopeWidth = sum . map sourceWidth . scopeSources

-- | Every column of the row, in order.
scopeColumns :: Scope -> [ScopeColumn]
scopeColumns = concatMap srcColumns . scopeSources

-- | The first column of that name in the sources (hidden ones too), with its position in the row.
findSourceColumn :: [Source] -> String -> Maybe (Int, ScopeColumn)
findSourceColumn sources name =
  case [ (off + i, c) | (off, s) <- zip (offsets sources) sources
                      , (i, c) <- zip [0 ..] (srcColumns s), foldName (scName c) == foldName name ] of
    hit : _ -> Just hit
    [] -> Nothing

offsets :: [Source] -> [Int]
offsets = scanl (+) 0 . map sourceWidth

-- | A name, qualified or not, as in SPEC 4.2: this query's sources, then (unqualified) its aliases,
-- then each enclosing query the same way. The error text spells the name as written.
resolveName :: Scope -> Maybe String -> String -> Either String Bound
resolveName sc qualifier name = case qualifier of
  Just q -> case [ (off, s) | (off, s) <- zip (offsets sources) sources, fmap foldName (srcName s) == Just (foldName q) ] of
    (off, s) : _ -> case findIndex ((== foldName name) . foldName . scName) (srcColumns s) of
      Just i -> Right (column (off + i) (srcColumns s !! i))
      Nothing -> unknown
    [] -> outer
  Nothing -> case [ column (off + i) c | (off, s) <- zip (offsets sources) sources
                                       , (i, c) <- zip [0 ..] (srcColumns s)
                                       , not (scHidden c), foldName (scName c) == foldName name ] of
    [b] -> Right b
    _ : _ -> Left ("ambiguous column name: " ++ name)
    [] -> case lookup (foldName name) (scopeAliases sc) of
      Just found -> found
      Nothing -> outer
  where
    sources = scopeSources sc
    written = maybe name (++ ('.' : name)) qualifier
    unknown = Left ("no such column: " ++ written)
    outer = maybe unknown (\o -> BShift 1 <$> resolveName o qualifier name) (scopeOuter sc)
    column i c = BCol i (scAffinity c)

-- | Only a column reference, a CAST, or a subquery returning a plain column has an affinity.
affinityOf :: Bound -> Maybe ColType
affinityOf (BCol _ t) = t >>= affinityOfType
affinityOf (BCast _ t) = affinityOfType t
affinityOf (BShift _ b) = affinityOf b
affinityOf (BScalarSub sq) = case sqColumns sq of
  c : _ -> scAffinity c
  [] -> Nothing
affinityOf _ = Nothing
