-- | The in-memory database: tables (with their constraints, indexes and rows), views and the
-- common tables of the statement being run, and the rule for storing a value in a column
-- (SPEC 1.4, 1.5, 2.1, 5). Row-level checks live in Engine.Constraints.
module Engine.Catalog
  ( Database
  , Column(..)
  , Table(..)
  , Index(..)
  , View(..)
  , tableUniqueKeys
  , tableSource
  , newTable
  , columnPosition
  , emptyDatabase
  , lookupTable
  , insertTable
  , removeTable
  , replaceTable
  , setRows
  , lookupView
  , insertView
  , removeView
  , lookupIndex
  , nameTaken
  , NameKind(..)
  , lookupCte
  , withCte
  , withoutCtes
  , columnDefault
  , coerceForColumn
  ) where

import Data.List (findIndex)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Sequence (Seq)
import Engine.Ast (ColumnConstraint(..), ColumnDef(..), Select, TableConstraint(..))
import Engine.Coerce (parseNumberText)
import Engine.Scope (ScopeColumn(..), Source(..), Subquery)
import Engine.Names (foldName)
import Engine.Value

-- | A column of a stored table.
data Column = Column { colName :: String, colType :: ColType }
  deriving (Show)

data Table = Table
  { tableName :: String          -- spelled as in CREATE TABLE
  , tableColumns :: [Column]
  , tableRows :: Seq [Value]     -- insertion order
  , tableNotNull :: [Bool]       -- per column: NOT NULL (also true for PRIMARY KEY columns)
  , tableDefaults :: [Value]     -- per column: DEFAULT, VNull when none
  , tableRowKey :: Maybe Int     -- the INTEGER PRIMARY KEY column, which numbers rows itself
  , tableUniques :: [[Int]]      -- UNIQUE / PRIMARY KEY column lists, in declaration order
  , tableIndexes :: [Index]      -- in creation order
  }

-- | An index. It changes no result; a UNIQUE one is also a uniqueness constraint (SPEC 5.7).
data Index = Index
  { indexName :: String          -- spelled as in CREATE INDEX
  , indexColumns :: [Int]        -- column positions
  , indexUnique :: Bool
  }

-- | A named select, run anew wherever it is used (SPEC 5.3). Its select is not checked when created.
data View = View
  { viewName :: String           -- spelled as in CREATE VIEW
  , viewColumns :: [String]      -- the column list; empty when none was written
  , viewSelect :: Select
  }

-- | Every uniqueness constraint of the table in declaration order: those of CREATE TABLE, then the
-- UNIQUE indexes. (A constraint is never added after the table is created: ADD COLUMN refuses them.)
tableUniqueKeys :: Table -> [[Int]]
tableUniqueKeys t = tableUniques t ++ [ indexColumns i | i <- tableIndexes t, indexUnique i ]

-- | An empty table from the CREATE TABLE definitions.
newTable :: String -> [ColumnDef] -> [TableConstraint] -> Either String Table
newTable name defs cons = do
  checkDuplicates [] defs
  let cols = [ Column (cdName d) (cdType d) | d <- defs ]
  -- (is primary key, columns) in declaration order: column constraints, then table constraints
  declared <- sequence $
    [ Right (isPk c, [i]) | (i, d) <- zip [0 ..] defs, c <- cdConstraints d, isKey c ]
    ++ [ (,) (isPkT c) <$> traverse (columnPosition cols) names
       | c <- cons, let names = tableConstraintColumns c ]
  let pkCols = concat [ cs | (True, cs) <- declared ]
      rowKey = case pkCols of
        [i] | cdType (defs !! i) == TInteger -> Just i
        _ -> Nothing
  Right Table
    { tableName = name
    , tableColumns = cols
    , tableRows = mempty
    , tableNotNull = [ any isNotNull (cdConstraints d) || i `elem` pkCols | (i, d) <- zip [0 ..] defs ]
    , tableDefaults = map columnDefault defs
    , tableRowKey = rowKey
    , tableUniques = [ cs | (isPkEntry, cs) <- declared, not (isPkEntry && isJust rowKey) ]
    , tableIndexes = []
    }
  where
    checkDuplicates _ [] = Right ()
    checkDuplicates seen (d : ds)
      | foldName (cdName d) `elem` seen = Left ("duplicate column name: " ++ cdName d)
      | otherwise = checkDuplicates (foldName (cdName d) : seen) ds
    isKey c = case c of CPrimaryKey -> True; CUnique -> True; _ -> False
    isPk c = case c of CPrimaryKey -> True; _ -> False
    isNotNull c = case c of CNotNull -> True; _ -> False
    isPkT c = case c of TPrimaryKey _ -> True; _ -> False
    tableConstraintColumns c = case c of TPrimaryKey ns -> ns; TUnique ns -> ns

-- | The DEFAULT of a column definition: the last one written, VNull when none.
columnDefault :: ColumnDef -> Value
columnDefault d = case [ v | CDefault v <- cdConstraints d ] of
  [] -> VNull
  vs -> last vs

-- | The table as a FROM source under the given name (its alias, or its own name).
tableSource :: String -> Table -> Source
tableSource name t = Source (Just name) [ ScopeColumn (colName c) (Just (colType c)) False | c <- tableColumns t ]

-- | Position of a column by name (case-insensitive).
columnPosition :: [Column] -> String -> Either String Int
columnPosition cols n = case findIndex ((== foldName n) . foldName . colName) cols of
  Just i -> Right i
  Nothing -> Left ("no such column: " ++ n)

-- | Tables and views by folded name (one name space, SPEC 5.3). @dbCtes@ holds the common tables
-- of the statement being planned; each is either usable or the error its use raises.
data Database = Database
  { dbTables :: Map.Map String Table
  , dbViews :: Map.Map String View
  , dbCtes :: Map.Map String (Either String Subquery)
  }

emptyDatabase :: Database
emptyDatabase = Database Map.empty Map.empty Map.empty

lookupTable :: String -> Database -> Maybe Table
lookupTable name db = Map.lookup (foldName name) (dbTables db)

-- | Add a table, or replace the one of that name.
insertTable :: Table -> Database -> Database
insertTable t db = db { dbTables = Map.insert (foldName (tableName t)) t (dbTables db) }

removeTable :: String -> Database -> Database
removeTable name db = db { dbTables = Map.delete (foldName name) (dbTables db) }

-- | Replace the table stored under @oldName@ by one that may have another name.
replaceTable :: String -> Table -> Database -> Database
replaceTable oldName t = insertTable t . removeTable oldName

-- | Replace the rows of a table of the database.
setRows :: String -> Seq [Value] -> Database -> Database
setRows name rows db = db { dbTables = Map.adjust (\t -> t { tableRows = rows }) (foldName name) (dbTables db) }

lookupView :: String -> Database -> Maybe View
lookupView name db = Map.lookup (foldName name) (dbViews db)

insertView :: View -> Database -> Database
insertView v db = db { dbViews = Map.insert (foldName (viewName v)) v (dbViews db) }

removeView :: String -> Database -> Database
removeView name db = db { dbViews = Map.delete (foldName name) (dbViews db) }

-- | The index of that name and the table it belongs to. Index names are unique across the database.
lookupIndex :: String -> Database -> Maybe (Table, Index)
lookupIndex name db = case [ (t, i) | t <- Map.elems (dbTables db), i <- tableIndexes t, same (indexName i) ] of
  hit : _ -> Just hit
  [] -> Nothing
  where same n = foldName n == foldName name

data NameKind = IsTable | IsView | IsIndex
  deriving (Eq)

-- | What a table / view / index name is already used for. Tables and views share one name space,
-- indexes have their own; callers decide which of them a new name must avoid.
nameTaken :: String -> Database -> [NameKind]
nameTaken name db =
  [ IsTable | Just _ <- [lookupTable name db] ] ++ [ IsView | Just _ <- [lookupView name db] ]
  ++ [ IsIndex | Just _ <- [lookupIndex name db] ]

lookupCte :: String -> Database -> Maybe (Either String Subquery)
lookupCte name db = Map.lookup (foldName name) (dbCtes db)

-- | Make a common table visible (hiding any table, view or earlier cte of that name).
withCte :: String -> Either String Subquery -> Database -> Database
withCte name rel db = db { dbCtes = Map.insert (foldName name) rel (dbCtes db) }

-- | The database a view's select runs in: the statement's ctes are not visible inside a view.
withoutCtes :: Database -> Database
withoutCtes db = db { dbCtes = Map.empty }

-- | Convert a value to the column's type, or reject it with the storage error message.
coerceForColumn :: Table -> Column -> Value -> Either String Value
coerceForColumn _ _ VNull = Right VNull
coerceForColumn tbl col v0 = case colType col of
  TText -> Right (case v0 of
    VText _ -> v0
    _ -> VText (textForm v0))
  TInteger -> case parsed of
    VInt _ -> Right parsed
    VReal d | wholeInt d -> Right (VInt (truncate d))
    _ -> reject parsed
  TReal -> case parsed of
    VInt n -> Right (VReal (fromIntegral n))
    VReal _ -> Right parsed
    _ -> reject parsed
  where
    -- text for a numeric column is parsed first
    parsed = case v0 of
      VText s -> fromMaybe v0 (parseNumberText s)
      _ -> v0
    reject v = Left ("cannot store " ++ valueTypeName v ++ " value in " ++ colTypeName (colType col)
                     ++ " column " ++ tableName tbl ++ "." ++ colName col)

-- | A REAL that is a whole number within 64 bits.
wholeInt :: Double -> Bool
wholeInt d = d >= -9.223372036854775808e18 && d < 9.223372036854775808e18
             && fromIntegral (truncate d :: Int) == d
