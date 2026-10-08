-- | The four value types of the engine, their text form and their order (SPEC 1.3, 1.9).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , textForm
  , compareValues
  , Collation(..)
  , CollSpec(..)
  , parseCollation
  , compareValuesC
  , isNull
  ) where

import Engine.Names (foldName)
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
compareValues = compareValuesC Binary

-- | A rule for comparing two TEXT values (SPEC 7.1).
data Collation = Binary | NoCase | RTrim
  deriving (Eq, Show)

-- | The collation of an expression as written: explicit (COLLATE) or implicit (a column's); no spec means none.
data CollSpec = CollSpec { csExplicit :: Bool, csCollation :: Collation }
  deriving (Eq, Show)

-- | A collation name, matched case-insensitively.
parseCollation :: String -> Maybe Collation
parseCollation n = case foldName n of
  "binary" -> Just Binary
  "nocase" -> Just NoCase
  "rtrim" -> Just RTrim
  _ -> Nothing

-- | 'compareValues' with the TEXT-to-TEXT case decided by a collation; every other pair is as in 1.9.
compareValuesC :: Collation -> Value -> Value -> Ordering
compareValuesC _ VNull VNull = EQ
compareValuesC _ VNull _ = LT
compareValuesC _ _ VNull = GT
compareValuesC c (VText a) (VText b) = case c of
  Binary -> compare a b
  NoCase -> compare (map lowerAscii a) (map lowerAscii b)
  RTrim -> compare (trimSpaces a) (trimSpaces b)
compareValuesC _ (VText _) _ = GT
compareValuesC _ _ (VText _) = LT
compareValuesC _ (VInt a) (VInt b) = compare a b
compareValuesC _ (VReal a) (VReal b) = compare a b
compareValuesC _ (VInt a) (VReal b) = compare (toRational a) (toRational b)
compareValuesC _ (VReal a) (VInt b) = compare (toRational a) (toRational b)

lowerAscii :: Char -> Char
lowerAscii ch = if ch >= 'A' && ch <= 'Z' then toEnum (fromEnum ch + 32) else ch

-- | Remove trailing spaces (only the space character).
trimSpaces :: String -> String
trimSpaces = reverse . dropWhile (== ' ') . reverse
