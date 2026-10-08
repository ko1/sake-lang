-- | The five value types of the engine, their text form and their order (SPEC 1.3, 1.9, 7).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , affinityOfType
  , textForm
  , printForm
  , hexOfBytes
  , compareValues
  , isNull
  ) where

import Data.Char (chr, intToDigit, ord)
import Engine.Real (formatReal)

data Value
  = VNull
  | VInt !Int
  | VReal !Double
  | VText String
  | VBlob String   -- one Char (0..255) per byte
  deriving (Eq, Show)

-- | Declared type of a column. It also acts as the column's affinity.
data ColType = TInteger | TReal | TText | TBlob
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName TInteger = "INTEGER"
colTypeName TReal = "REAL"
colTypeName TText = "TEXT"
colTypeName TBlob = "BLOB"

-- | The affinity a declared type gives (SPEC 1.9, 7.3): a BLOB type has none.
affinityOfType :: ColType -> Maybe ColType
affinityOfType TBlob = Nothing
affinityOfType t = Just t

-- | Type name as used in storage errors (SPEC 7.4); an INTEGER value is 'INT' there.
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INT"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"
valueTypeName (VBlob _) = "BLOB"

isNull :: Value -> Bool
isNull VNull = True
isNull _ = False

-- | The text form of a value (SPEC 1.3); a BLOB's is its bytes read as characters (SPEC 7.1).
textForm :: Value -> String
textForm VNull = "NULL"
textForm (VInt n) = show n
textForm (VReal d) = formatReal d
textForm (VText s) = s
textForm (VBlob s) = s

-- | How a result value is printed: the text form, except that a BLOB prints as X'..' (SPEC 7.1).
printForm :: Value -> String
printForm (VBlob s) = "X'" ++ hexOfBytes s ++ "'"
printForm v = textForm v

-- | Two uppercase hexadecimal digits per byte (a Char is taken as a byte).
hexOfBytes :: String -> String
hexOfBytes = concatMap byte
  where
    byte c = let n = ord c `mod` 256 in [digit (n `div` 16), digit (n `mod` 16)]
    digit = upper . intToDigit
    upper d = if d >= 'a' && d <= 'f' then chr (ord d - 32) else d

-- | Order of values: NULL < numbers < TEXT < BLOB; numbers by value across types, BLOBs byte by byte.
compareValues :: Value -> Value -> Ordering
compareValues VNull VNull = EQ
compareValues VNull _ = LT
compareValues _ VNull = GT
compareValues (VBlob a) (VBlob b) = compare a b
compareValues (VBlob _) _ = GT
compareValues _ (VBlob _) = LT
compareValues (VText a) (VText b) = compare a b
compareValues (VText _) _ = GT
compareValues _ (VText _) = LT
compareValues (VInt a) (VInt b) = compare a b
compareValues (VReal a) (VReal b) = compare a b
compareValues (VInt a) (VReal b) = compare (toRational a) (toRational b)
compareValues (VReal a) (VInt b) = compare (toRational a) (toRational b)
