-- | SQL errors. Every user-visible message is built here so the wording
-- lives in one place; the runner prints it as @Error: <message>@.
module Engine.Error
  ( SqlError (..)
  , SqlFailure (..)
  , Result
  , orElse
  , noSuchTable
  , noSuchColumn
  , noSuchFunction
  , wrongArgCount
  , tableExists
  , duplicateColumn
  , noColumnNamed
  , cannotStore
  , insertCountMismatch
  , insertListMismatch
  , valuesTermMismatch
  , orderByRange
  , noTablesSpecified
  , notNullFailed
  , uniqueFailed
  , datatypeMismatch
  , misuseOfAggregate
  , misuseOfAggregateAlias
  , groupByAggregate
  , havingNonAggregate
  , distinctArity
  , groupByRange
  , integerOverflow
  , ambiguousColumn
  , subSelectColumns
  , rowValueMisused
  , joinColumnMissing
  ) where

import Control.Exception (Exception)
import Data.List (intercalate)

-- | The message of an error, without the @Error: @ prefix.
newtype SqlError = SqlError String
  deriving (Eq, Show)

type Result = Either SqlError

-- | An error found while a subquery runs inside a pure row function; it is
-- thrown as an exception and turned back into a 'SqlError' by "Engine.Exec".
newtype SqlFailure = SqlFailure SqlError
  deriving (Show)

instance Exception SqlFailure

-- | Turn a 'Maybe' into a 'Result' with the given error.
orElse :: Maybe a -> SqlError -> Result a
orElse (Just x) _ = Right x
orElse Nothing e = Left e

noSuchTable, noSuchColumn, noSuchFunction, tableExists, duplicateColumn :: String -> SqlError
noSuchTable n = SqlError ("no such table: " ++ n)
noSuchColumn n = SqlError ("no such column: " ++ n)
noSuchFunction n = SqlError ("no such function: " ++ n)
tableExists n = SqlError ("table " ++ n ++ " already exists")
duplicateColumn n = SqlError ("duplicate column name: " ++ n)

wrongArgCount :: String -> SqlError
wrongArgCount n = SqlError ("wrong number of arguments to function " ++ n ++ "()")

-- | @noColumnNamed table column@.
noColumnNamed :: String -> String -> SqlError
noColumnNamed t c = SqlError ("table " ++ t ++ " has no column named " ++ c)

-- | @cannotStore valueType columnType table column@.
cannotStore :: String -> String -> String -> String -> SqlError
cannotStore vt ct t c =
  SqlError ("cannot store " ++ vt ++ " value in " ++ ct ++ " column " ++ t ++ "." ++ c)

-- | @insertCountMismatch table columns values@ (no column list given).
insertCountMismatch :: String -> Int -> Int -> SqlError
insertCountMismatch t n m =
  SqlError ("table " ++ t ++ " has " ++ show n ++ " columns but " ++ show m ++ " values were supplied")

-- | @insertListMismatch values columns@ (column list given).
insertListMismatch :: Int -> Int -> SqlError
insertListMismatch m n = SqlError (show m ++ " values for " ++ show n ++ " columns")

valuesTermMismatch :: SqlError
valuesTermMismatch = SqlError "all VALUES must have the same number of terms"

-- | @orderByRange position columns@; position is 1-based.
orderByRange :: Int -> Int -> SqlError
orderByRange i n =
  SqlError (ordinal i ++ " ORDER BY term out of range - should be between 1 and " ++ show n)

-- | @notNullFailed table column@.
notNullFailed :: String -> String -> SqlError
notNullFailed t c = SqlError ("NOT NULL constraint failed: " ++ t ++ "." ++ c)

-- | @uniqueFailed table columns@.
uniqueFailed :: String -> [String] -> SqlError
uniqueFailed t cs =
  SqlError ("UNIQUE constraint failed: " ++ intercalate ", " [t ++ "." ++ c | c <- cs])

datatypeMismatch :: SqlError
datatypeMismatch = SqlError "datatype mismatch"

noTablesSpecified :: SqlError
noTablesSpecified = SqlError "no tables specified"

ordinal :: Int -> String
ordinal i = show i ++ suffix
  where
    suffix
      | i `mod` 100 `elem` [11, 12, 13] = "th"
      | i `mod` 10 == 1 = "st"
      | i `mod` 10 == 2 = "nd"
      | i `mod` 10 == 3 = "rd"
      | otherwise = "th"

-- | An aggregate call where none is allowed (WHERE, nested, UPDATE ...).
misuseOfAggregate :: String -> SqlError
misuseOfAggregate n = SqlError ("misuse of aggregate function " ++ n ++ "()")

-- | The same, reached through a result-column alias or from ORDER BY of a non-aggregate query.
misuseOfAggregateAlias :: String -> SqlError
misuseOfAggregateAlias n = SqlError ("misuse of aggregate: " ++ n ++ "()")

groupByAggregate :: String -> SqlError
groupByAggregate _ = SqlError "aggregate functions are not allowed in the GROUP BY clause"

havingNonAggregate, distinctArity, integerOverflow :: SqlError
havingNonAggregate = SqlError "HAVING clause on a non-aggregate query"
distinctArity = SqlError "DISTINCT aggregates must have exactly one argument"
integerOverflow = SqlError "integer overflow"

-- | @groupByRange position columns@; position is 1-based.
groupByRange :: Int -> Int -> SqlError
groupByRange i n =
  SqlError (ordinal i ++ " GROUP BY term out of range - should be between 1 and " ++ show n)

ambiguousColumn :: String -> SqlError
ambiguousColumn n = SqlError ("ambiguous column name: " ++ n)

-- | @subSelectColumns n@: a subquery used as one value has @n@ result columns.
subSelectColumns :: Int -> SqlError
subSelectColumns n = SqlError ("sub-select returns " ++ show n ++ " columns - expected 1")

rowValueMisused :: SqlError
rowValueMisused = SqlError "row value misused"

-- | A @USING@ column that is not in both sides of a join.
joinColumnMissing :: String -> SqlError
joinColumnMissing c = SqlError ("cannot join using column " ++ c ++ " - column not present in both tables")
