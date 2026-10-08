-- | The database: tables, views and indexes, plus the open transaction's undo point.
module Engine.Catalog
  ( Column (..)
  , Row
  , UniqueKey (..)
  , Table (..)
  , View (..)
  , Index (..)
  , Database
  , emptyDatabase
  , findTable
  , findView
  , lookupIndex
  , addTable
  , removeTable
  , replaceTable
  , addView
  , removeView
  , addIndex
  , removeIndex
  , indexesOf
  , setRows
  , forceRows
  , inTransaction
  , beginTransaction
  , commitTransaction
  , rollbackTransaction
  ) where

import qualified Data.Map.Strict as Map
import Data.Sequence (Seq)
import Engine.Syntax (Ident, Query, identKey)
import Engine.Value (ColType, Collation, Value)

type Row = [Value]

-- | A column with its name spelled as in @CREATE TABLE@.
data Column = Column
  { columnName :: Ident
  , columnType :: ColType
  , columnNotNull :: Bool -- ^ declared NOT NULL, or part of a PRIMARY KEY
  , columnDefault :: Value -- ^ what an INSERT stores when the column gets no value
  , columnCollation :: Collation -- ^ how its TEXT values compare (SPEC 7.2)
  }

-- | A uniqueness constraint on columns (indexes into 'tableColumns').
data UniqueKey = UniqueKey
  { ukColumns :: [Int]
  , ukCollations :: [Collation] -- ^ per column: the column's, or the one a UNIQUE index gave it
  , ukIndex :: Maybe Ident -- ^ the UNIQUE index that declared it, if any (dropped with it)
  }

data Table = Table
  { tableName :: Ident -- ^ spelled as in @CREATE TABLE@
  , tableColumns :: [Column]
  , tableRows :: Seq Row -- ^ in insertion order
  , tableRowKey :: Maybe Int -- ^ the INTEGER PRIMARY KEY column (an index into 'tableColumns')
  , tableUniques :: [UniqueKey] -- ^ UNIQUE / other PRIMARY KEY / UNIQUE INDEX constraints, in declaration order
  }

-- | A named select (SPEC 5.3), run anew wherever it is used.
data View = View
  { viewName :: Ident -- ^ spelled as in @CREATE VIEW@
  , viewColumns :: Maybe [Ident]
  , viewQuery :: Query
  }

-- | An index (SPEC 5.7). It changes no result; a UNIQUE one is also a 'UniqueKey' of its table.
data Index = Index
  { indexName :: Ident
  , indexTable :: Ident -- ^ the table's current name
  }

-- | Tables, views and indexes by case-insensitive name. Tables and views share
-- one name space, indexes have their own. 'dbSaved' is the state at BEGIN.
data Database = Database
  { dbTables :: Map.Map String Table
  , dbViews :: Map.Map String View
  , dbIndexes :: Map.Map String Index
  , dbSaved :: Maybe Database
  }

emptyDatabase :: Database
emptyDatabase = Database Map.empty Map.empty Map.empty Nothing

findTable :: Ident -> Database -> Maybe Table
findTable name = Map.lookup (identKey name) . dbTables

findView :: Ident -> Database -> Maybe View
findView name = Map.lookup (identKey name) . dbViews

lookupIndex :: Ident -> Database -> Maybe Index
lookupIndex name = Map.lookup (identKey name) . dbIndexes

-- | Add a table (replacing any with the same name).
addTable :: Table -> Database -> Database
addTable t db = db {dbTables = Map.insert (identKey (tableName t)) t (dbTables db)}

-- | Drop a table together with its indexes.
removeTable :: Ident -> Database -> Database
removeTable name db =
  db { dbTables = Map.delete (identKey name) (dbTables db)
     , dbIndexes = Map.filter (\i -> identKey (indexTable i) /= identKey name) (dbIndexes db) }

-- | Put a changed table in place of the table called @old@ (which may be renamed); its indexes follow.
replaceTable :: Ident -> Table -> Database -> Database
replaceTable old t db =
  db { dbTables = Map.insert (identKey (tableName t)) t (Map.delete (identKey old) (dbTables db))
     , dbIndexes = Map.map follow (dbIndexes db) }
  where
    follow i
      | identKey (indexTable i) == identKey old = i {indexTable = tableName t}
      | otherwise = i

addView :: View -> Database -> Database
addView v db = db {dbViews = Map.insert (identKey (viewName v)) v (dbViews db)}

removeView :: Ident -> Database -> Database
removeView name db = db {dbViews = Map.delete (identKey name) (dbViews db)}

addIndex :: Index -> Database -> Database
addIndex i db = db {dbIndexes = Map.insert (identKey (indexName i)) i (dbIndexes db)}

removeIndex :: Ident -> Database -> Database
removeIndex name db = db {dbIndexes = Map.delete (identKey name) (dbIndexes db)}

-- | The indexes on a table.
indexesOf :: Ident -> Database -> [Index]
indexesOf name db = [i | i <- Map.elems (dbIndexes db), identKey (indexTable i) == identKey name]

-- | Replace all rows of an existing table (already checked and converted).
setRows :: Ident -> Seq Row -> Database -> Database
setRows name rows db = db {dbTables = Map.adjust (\t -> t {tableRows = rows}) (identKey name) (dbTables db)}

-- | Evaluate every value stored in a table, so that a failure hidden in a
-- lazy value shows now rather than at some later statement.
forceRows :: Ident -> Database -> ()
forceRows name db = case findTable name db of
  Nothing -> ()
  Just t -> foldl' (\u row -> foldl' (\v x -> x `seq` v) u row) () (tableRows t)

-- Transactions (SPEC 5.5): the whole database is immutable, so BEGIN just keeps it.

inTransaction :: Database -> Bool
inTransaction db = case dbSaved db of
  Just _ -> True
  Nothing -> False

beginTransaction :: Database -> Database
beginTransaction db = db {dbSaved = Just db}

commitTransaction :: Database -> Database
commitTransaction db = db {dbSaved = Nothing}

-- | The database as it was at BEGIN (unchanged if no transaction is open).
rollbackTransaction :: Database -> Database
rollbackTransaction db = maybe db id (dbSaved db)
