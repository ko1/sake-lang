-- | The database: tables with typed columns and their rows.
module Engine.Catalog
  ( Column (..)
  , Row
  , Table (..)
  , Database
  , emptyDatabase
  , findTable
  , addTable
  , removeTable
  , setRows
  , forceRows
  ) where

import qualified Data.Map.Strict as Map
import Data.Sequence (Seq)
import Engine.Syntax (Ident, identKey)
import Engine.Value (ColType, Value)

type Row = [Value]

-- | A column with its name spelled as in @CREATE TABLE@.
data Column = Column
  { columnName :: Ident
  , columnType :: ColType
  , columnNotNull :: Bool -- ^ declared NOT NULL, or part of a PRIMARY KEY
  , columnDefault :: Value -- ^ what an INSERT stores when the column gets no value
  }

data Table = Table
  { tableName :: Ident -- ^ spelled as in @CREATE TABLE@
  , tableColumns :: [Column]
  , tableRows :: Seq Row -- ^ in insertion order
  , tableRowKey :: Maybe Int -- ^ the INTEGER PRIMARY KEY column (an index into 'tableColumns')
  , tableUniques :: [[Int]] -- ^ UNIQUE / other PRIMARY KEY column lists, in declaration order
  }

-- | Tables by case-insensitive name.
newtype Database = Database (Map.Map String Table)

emptyDatabase :: Database
emptyDatabase = Database Map.empty

findTable :: Ident -> Database -> Maybe Table
findTable name (Database m) = Map.lookup (identKey name) m

-- | Add a table (replacing any with the same name).
addTable :: Table -> Database -> Database
addTable t (Database m) = Database (Map.insert (identKey (tableName t)) t m)

removeTable :: Ident -> Database -> Database
removeTable name (Database m) = Database (Map.delete (identKey name) m)

-- | Replace all rows of an existing table (already checked and converted).
setRows :: Ident -> Seq Row -> Database -> Database
setRows name rows (Database m) = Database (Map.adjust (\t -> t {tableRows = rows}) (identKey name) m)

-- | Evaluate every value stored in a table, so that a failure hidden in a
-- lazy value shows now rather than at some later statement.
forceRows :: Ident -> Database -> ()
forceRows name db = case findTable name db of
  Nothing -> ()
  Just t -> foldl' (\u row -> foldl' (\v x -> x `seq` v) u row) () (tableRows t)
