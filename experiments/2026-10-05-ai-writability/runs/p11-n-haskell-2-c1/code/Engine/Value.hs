-- | The four value types of the engine, their text form and their order (SPEC 1.3, 1.9).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , textForm
  , compareValues
  , isNull
  , Collation(..)
  , CollSource(..)
  , collSourceCollation
  , lookupCollation
  , collationNamed
  , collKey
  , compareValuesC
  , pickCollation
  ) where

import Data.List (dropWhileEnd)
import Engine.Names (upperAscii)
import Engine.Real (formatReal)

data Value
  = VNull
  | VInt !Int
  | VReal !Double
  | VText String
  deriving (Eq, Show)

-- | Declared type of a column. It also acts as the column's affinity.
data ColType = TInteger | TReal | TText
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName TInteger = "INTEGER"
colTypeName TReal = "REAL"
colTypeName TText = "TEXT"

-- | Type name as used in storage errors ('NULL', 'INTEGER', ...).
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INTEGER"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"

isNull :: Value -> Bool
isNull VNull = True
isNull _ = False

-- | The text form of a value; this is also how result values are printed.
textForm :: Value -> String
textForm VNull = "NULL"
textForm (VInt n) = show n
textForm (VReal d) = formatReal d
textForm (VText s) = s

-- | Order of values: NULL < numbers < TEXT; numbers by value across types.
compareValues :: Value -> Value -> Ordering
compareValues VNull VNull = EQ
compareValues VNull _ = LT
compareValues _ VNull = GT
compareValues (VText a) (VText b) = compare a b
compareValues (VText _) _ = GT
compareValues _ (VText _) = LT
compareValues (VInt a) (VInt b) = compare a b
compareValues (VReal a) (VReal b) = compare a b
compareValues (VInt a) (VReal b) = compare (toRational a) (toRational b)
compareValues (VReal a) (VInt b) = compare (toRational a) (toRational b)

-- | How two TEXT values compare (SPEC 7.1).
data Collation = Binary | NoCase | RTrim
  deriving (Eq, Show)

-- | The collation of an expression, and whether it was written with COLLATE (SPEC 7.3).
data CollSource = Explicit Collation | Implicit Collation
  deriving (Eq, Show)

collSourceCollation :: CollSource -> Collation
collSourceCollation (Explicit c) = c
collSourceCollation (Implicit c) = c

-- | A collation by name, case-insensitively; Nothing for an unknown name.
lookupCollation :: String -> Maybe Collation
lookupCollation name = case upperAscii name of
  "BINARY" -> Just Binary
  "NOCASE" -> Just NoCase
  "RTRIM" -> Just RTrim
  _ -> Nothing

-- | 'lookupCollation' with the error of SPEC 7.2 (the name as written) for an unknown one.
collationNamed :: String -> Either String Collation
collationNamed name = maybe (Left ("no such collation sequence: " ++ name)) Right (lookupCollation name)

-- | A value rewritten so that plain 'compareValues' on the results orders and equates as the collation does.
-- This also lets it key a Set or Map ('Engine.Sorting.ValueKey').
collKey :: Collation -> Value -> Value
collKey NoCase (VText s) = VText (map lowerAscii s)
  where lowerAscii c = if c >= 'A' && c <= 'Z' then toEnum (fromEnum c + 32) else c
collKey RTrim (VText s) = VText (dropWhileEnd (== ' ') s)
collKey _ v = v

-- | 'compareValues' with TEXT compared under a collation (NULL and numbers are unaffected).
compareValuesC :: Collation -> Value -> Value -> Ordering
compareValuesC Binary a b = compareValues a b
compareValuesC c a b = compareValues (collKey c a) (collKey c b)

-- | The collation of a comparison of two operands (SPEC 7.4): an explicit one (left first), else an
-- implicit one (left first), else BINARY.
pickCollation :: Maybe CollSource -> Maybe CollSource -> Collation
pickCollation a b = case [ c | Just (Explicit c) <- [a, b] ] ++ [ c | Just (Implicit c) <- [a, b] ] of
  c : _ -> c
  [] -> Binary
