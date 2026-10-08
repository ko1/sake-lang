-- | The in-memory database: tables, their rows, and the rule for storing a value in a column (SPEC 1.4, 1.5).
module Engine.Catalog
  ( Database
  , Table(..)
  , emptyDatabase
  , lookupTable
  , insertTable
  , removeTable
  , appendRows
  , coerceForColumn
  ) where

import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Sequence (Seq, (|>))
import Engine.Coerce (parseNumberText)
import Engine.Expr (Column(..))
import Engine.Names (foldName)
import Engine.Value

data Table = Table
  { tableName :: String          -- spelled as in CREATE TABLE
  , tableColumns :: [Column]
  , tableRows :: Seq [Value]     -- insertion order
  }

-- | Tables by folded name.
newtype Database = Database (Map.Map String Table)

emptyDatabase :: Database
emptyDatabase = Database Map.empty

lookupTable :: String -> Database -> Maybe Table
lookupTable name (Database m) = Map.lookup (foldName name) m

insertTable :: Table -> Database -> Database
insertTable t (Database m) = Database (Map.insert (foldName (tableName t)) t m)

removeTable :: String -> Database -> Database
removeTable name (Database m) = Database (Map.delete (foldName name) m)

-- | Append rows (already coerced) to a table of the database.
appendRows :: String -> [[Value]] -> Database -> Database
appendRows name rows (Database m) = Database (Map.adjust add (foldName name) m)
  where add t = t { tableRows = foldl (|>) (tableRows t) rows }

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
