-- | The in-memory database: tables with their constraints and rows, and the rule for
-- storing a value in a column (SPEC 1.4, 1.5, 2.1). Row-level checks live in Engine.Constraints.
module Engine.Catalog
  ( Database
  , Column(..)
  , Table(..)
  , tableSource
  , newTable
  , columnPosition
  , emptyDatabase
  , lookupTable
  , insertTable
  , removeTable
  , setRows
  , coerceForColumn
  ) where

import Data.List (findIndex)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Sequence (Seq)
import Engine.Ast (ColumnConstraint(..), ColumnDef(..), TableConstraint(..))
import Engine.Coerce (parseNumberText)
import Engine.Scope (ScopeColumn(..), Source(..))
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
  }

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
    , tableDefaults = [ lastDefault (cdConstraints d) | d <- defs ]
    , tableRowKey = rowKey
    , tableUniques = [ cs | (isPkEntry, cs) <- declared, not (isPkEntry && isJust rowKey) ]
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
    lastDefault cs = case [ v | CDefault v <- cs ] of
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

-- | Replace the rows of a table of the database.
setRows :: String -> Seq [Value] -> Database -> Database
setRows name rows (Database m) = Database (Map.adjust (\t -> t { tableRows = rows }) (foldName name) m)

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
