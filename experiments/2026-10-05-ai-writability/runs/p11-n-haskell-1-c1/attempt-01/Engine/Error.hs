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
  , noSuchCollation
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
  , compoundMismatch
  , orderByNoMatch
  , duplicateCte
  , viewExists
  , modifyView
  , dropTableOnView
  , dropViewOnTable
  , noSuchView
  , transactionActive
  , noTransaction
  , addNotNullColumn
  , addUniqueColumn
  , addPrimaryKeyColumn
  , renameTaken
  , noSuchColumnQuoted
  , indexExists
  , tableNamed
  , noSuchIndex
  , indexNamed
  , viewNotAlterable
  , viewNotIndexed
  , misuseOfWindow
  , misuseOfAliasedWindow
  , noSuchWindow
  , duplicateWindow
  , notWindowFunction
  , unsupportedFrame
  , frameOffset
  , rangeNeedsOneOrder
  , ntileArgument
  , nthValueArgument
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

-- | An unknown collation name, spelled as written.
noSuchCollation :: String -> SqlError
noSuchCollation n = SqlError ("no such collation sequence: " ++ n)
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

-- | @compoundMismatch op@ (the operator as written: UNION ALL, INTERSECT ...).
compoundMismatch :: String -> SqlError
compoundMismatch op =
  SqlError ("SELECTs to the left and right of " ++ op ++ " do not have the same number of result columns")

-- | @orderByNoMatch position@; position is 1-based.
orderByNoMatch :: Int -> SqlError
orderByNoMatch i = SqlError (ordinal i ++ " ORDER BY term does not match any column in the result set")

duplicateCte, viewExists, modifyView, dropTableOnView, dropViewOnTable, noSuchView :: String -> SqlError
duplicateCte n = SqlError ("duplicate WITH table name: " ++ n)
viewExists n = SqlError ("view " ++ n ++ " already exists")
modifyView n = SqlError ("cannot modify " ++ n ++ " because it is a view")
dropTableOnView n = SqlError ("use DROP VIEW to delete view " ++ n)
dropViewOnTable n = SqlError ("use DROP TABLE to delete table " ++ n)
noSuchView n = SqlError ("no such view: " ++ n)

transactionActive :: SqlError
transactionActive = SqlError "cannot start a transaction within a transaction"

-- | @noTransaction verb@: COMMIT or ROLLBACK with no transaction open.
noTransaction :: String -> SqlError
noTransaction verb = SqlError ("cannot " ++ verb ++ " - no transaction is active")

addNotNullColumn, addUniqueColumn, addPrimaryKeyColumn :: SqlError
addNotNullColumn = SqlError "Cannot add a NOT NULL column with default value NULL"
addUniqueColumn = SqlError "Cannot add a UNIQUE column"
addPrimaryKeyColumn = SqlError "Cannot add a PRIMARY KEY column"

renameTaken, noSuchColumnQuoted, indexExists, tableNamed, noSuchIndex, indexNamed, viewNotAlterable, viewNotIndexed :: String -> SqlError
renameTaken n = SqlError ("there is already another table or index with this name: " ++ n)
noSuchColumnQuoted n = SqlError ("no such column: \"" ++ n ++ "\"")
indexExists n = SqlError ("index " ++ n ++ " already exists")
tableNamed n = SqlError ("there is already a table named " ++ n)
noSuchIndex n = SqlError ("no such index: " ++ n)
indexNamed n = SqlError ("there is already an index named " ++ n)
viewNotAlterable n = SqlError ("view " ++ n ++ " may not be altered")
viewNotIndexed _ = SqlError "views may not be indexed"

-- Window functions (SPEC 6.4) ---------------------------------------------

-- | A window call where none is allowed, or a window-only function without OVER.
misuseOfWindow :: String -> SqlError
misuseOfWindow n = SqlError ("misuse of window function " ++ n ++ "()")

-- | A result-column alias containing a window call, used where none is allowed.
misuseOfAliasedWindow :: String -> SqlError
misuseOfAliasedWindow n = SqlError ("misuse of aliased window function " ++ n)

noSuchWindow, duplicateWindow, notWindowFunction :: String -> SqlError
noSuchWindow n = SqlError ("no such window: " ++ n)
duplicateWindow n = SqlError ("duplicate WINDOW name: " ++ n)
notWindowFunction n = SqlError (n ++ "() may not be used as a window function")

unsupportedFrame, rangeNeedsOneOrder, ntileArgument, nthValueArgument :: SqlError
unsupportedFrame = SqlError "unsupported frame specification"
rangeNeedsOneOrder = SqlError "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
ntileArgument = SqlError "argument of ntile must be a positive integer"
nthValueArgument = SqlError "second argument to nth_value must be a positive integer"

-- | @frameOffset isStart isRows@: a negative frame offset.
frameOffset :: Bool -> Bool -> SqlError
frameOffset isStart isRows =
  SqlError ("frame " ++ (if isStart then "starting" else "ending") ++ " offset must be a non-negative "
            ++ (if isRows then "integer" else "number"))
