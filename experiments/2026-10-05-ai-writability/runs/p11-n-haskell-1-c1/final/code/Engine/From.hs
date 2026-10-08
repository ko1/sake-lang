-- | The FROM clause (SPEC 4.1): resolving each from-item to a 'Source' and
-- joining their rows.
module Engine.From
  ( Derived
  , buildFrom
  , expandStar
  ) where

import Data.List (findIndex)
import Engine.Catalog
import Engine.Compile
import Engine.Error
import Engine.Operators (binaryOp)
import Engine.Syntax
import Engine.Value

-- | Run a subquery that appears as a from-item: its result columns and rows.
type Derived = Query -> Result ([ScopeColumn], [Row])

-- | Look up a table, view or WITH table by name: its columns and rows.
type NamedSource = Ident -> Result ([ScopeColumn], [Row])

-- | The sources of a FROM clause, and the joined rows given the environment
-- of the enclosing queries (an @ON@ may refer to them). Without a FROM there
-- is one empty row. @parent@ is the scope around the query the clause belongs to.
buildFrom :: NamedSource -> Derived -> SubqueryCompiler -> Maybe Scope -> Maybe FromClause -> Result ([Source], Env -> [Row])
buildFrom _ _ _ _ Nothing = Right ([], const [[]])
buildFrom named derived compile parent (Just (FromClause first joins)) = do
  (source, rows) <- resolveItem first
  go [source] (const rows) joins
  where
    go sources rowsOf [] = Right (sources, rowsOf)
    go sources rowsOf (Join kind item constraint : rest) = do
      (right, rightRows) <- resolveItem item
      (right', matches) <- constrain sources right constraint
      let rowsOf' env =
            joinRows kind (sourceWidth right') (matches env) (rowsOf env) rightRows
      go (sources ++ [right']) rowsOf' rest

    resolveItem (FromTable name alias) = do
      (cols, rows) <- named name
      Right (Source (Just (maybe name id alias)) cols, rows)
    resolveItem (FromSubquery sel alias) = do
      (cols, rows) <- derived sel
      Right (Source alias cols, rows)

    scopeOf = newScope compile parent

    -- The join condition as a test on a combined row (given the enclosing environment).
    constrain sources right constraint = case constraint of
      NoConstraint -> Right (right, \_ _ -> True)
      On e -> do
        (_, f) <- compileExpr (scopeOf (sources ++ [right])) e
        Right (right, \env row -> truthValue (f (row : env)) == Just True)
      Using names -> do
        pairs <- mapM (usingPair sources right) names
        let merged = [j | (_, j, _, _, _) <- pairs]
            right' = right {sourceColumns = [ if j `elem` merged then c {scMerged = True} else c
                                            | (j, c) <- zip [0 ..] (sourceColumns right) ]}
            offset = sourcesWidth sources
            test row = and [ binaryOp Eq la ra coll (row !! li) (row !! (offset + rj)) == VInt 1
                           | (li, rj, la, ra, coll) <- pairs ]
        Right (right', \_ row -> test row)

    -- (position in the left row, position in the right source, affinities, the left column's collation) of a USING column
    usingPair sources right name =
      case ( [ (o + j, c)
             | (o, s) <- zip (scanl (+) 0 (map sourceWidth sources)) sources
             , (j, c) <- zip [0 ..] (sourceColumns s), identKey (scName c) == identKey name ]
           , findIndex (\c -> identKey (scName c) == identKey name) (sourceColumns right) ) of
        ((li, lc) : _, Just rj) -> Right (li, rj, scAffinity lc, scAffinity (sourceColumns right !! rj), scopeColumnCollation lc)
        _ -> Left (joinColumnMissing name)

-- | Pair the rows of the left side with those of the right side.
joinRows :: JoinKind -> Int -> (Row -> Bool) -> [Row] -> [Row] -> [Row]
joinRows kind rightWidth matches lefts rights = concatMap pairs lefts
  where
    pairs l = case [row | r <- rights, let row = l ++ r, matches row] of
      [] | kind == LeftJoin -> [l ++ replicate rightWidth VNull]
      found -> found

-- | The result columns @*@ (all sources) or @q.*@ stands for, as column references.
expandStar :: [Source] -> Maybe Ident -> Result [(Expr, Maybe Ident)]
expandStar sources Nothing
  | null sources = Left noTablesSpecified
  | otherwise = Right (concatMap (refs False) sources)
expandStar sources (Just q) =
  case [s | s <- sources, fmap identKey (sourceName s) == Just (identKey q)] of
    s : _ -> Right (refs True s)
    [] -> Left (noSuchTable q)

refs :: Bool -> Source -> [(Expr, Maybe Ident)]
refs withMerged s =
  [ (EColumn (sourceName s) (scName c), Nothing)
  | c <- sourceColumns s, withMerged || not (scMerged c) ]
