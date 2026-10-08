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
  , appendRows
  ) where

import qualified Data.Map.Strict as Map
import Data.Sequence (Seq, (><))
import qualified Data.Sequence as Seq
import Engine.Syntax (Ident, identKey)
import Engine.Value (ColType, Value)

type Row = [Value]

-- | A column with its name spelled as in @CREATE TABLE@.
data Column = Column
  { columnName :: Ident
  , columnType :: ColType
  }

data Table = Table
  { tableName :: Ident -- ^ spelled as in @CREATE TABLE@
  , tableColumns :: [Column]
  , tableRows :: Seq Row -- ^ in insertion order
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

-- | Append rows (already converted to column types) to an existing table.
appendRows :: Ident -> [Row] -> Database -> Database
appendRows name rows (Database m) = Database (Map.adjust add (identKey name) m)
  where
    add t = t {tableRows = tableRows t >< Seq.fromList rows}
