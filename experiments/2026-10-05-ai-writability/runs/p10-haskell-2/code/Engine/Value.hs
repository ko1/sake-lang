-- | The four value types of the engine, their text form and their order (SPEC 1.3, 1.9).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , textForm
  , compareValues
  , isNull
  ) where

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
