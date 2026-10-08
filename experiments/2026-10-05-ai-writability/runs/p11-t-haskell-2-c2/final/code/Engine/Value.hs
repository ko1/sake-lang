-- | The five value types of the engine, their text form and their order (SPEC 1.3, 1.9).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , textForm
  , displayForm
  , utf8Bytes
  , affinityOfType
  , compareValues
  , isNull
  ) where

import Data.Bits (shiftR, (.&.), (.|.))
import Data.Char (chr, ord, intToDigit)
import Engine.Real (formatReal)

data Value
  = VNull
  | VInt !Int
  | VReal !Double
  | VText String
  | VBlob String          -- one Char (0-255) per byte
  deriving (Eq, Show)

-- | Declared type of a column. It also acts as the column's affinity.
data ColType = TInteger | TReal | TText | TBlob
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName TInteger = "INTEGER"
colTypeName TReal = "REAL"
colTypeName TText = "TEXT"
colTypeName TBlob = "BLOB"

-- | The affinity a declared type gives (SPEC 7.3): BLOB has none.
affinityOfType :: ColType -> Maybe ColType
affinityOfType TBlob = Nothing
affinityOfType t = Just t

-- | Type name as used in storage errors ('NULL', 'INTEGER', ...).
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INT"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"
valueTypeName (VBlob _) = "BLOB"

isNull :: Value -> Bool
isNull VNull = True
isNull _ = False

-- | The text form of a value (SPEC 1.3, 7.1).
textForm :: Value -> String
textForm VNull = "NULL"
textForm (VInt n) = show n
textForm (VReal d) = formatReal d
textForm (VText s) = s
textForm (VBlob s) = s     -- SPEC 7.1: bytes read as characters

-- | How a result value is printed (SPEC 1.3, 7.1): like 'textForm' except for BLOB.
displayForm :: Value -> String
displayForm (VBlob s) = "X'" ++ concatMap hexByte s ++ "'"
displayForm v = textForm v

hexByte :: Char -> String
hexByte c = [intToDigit' (ord c `shiftR` 4), intToDigit' (ord c .&. 15)]
  where intToDigit' = toUpperHex . intToDigit
        toUpperHex d = if d >= 'a' then chr (ord d - 32) else d

-- | UTF-8 bytes of a string, as characters 0-255.
utf8Bytes :: String -> String
utf8Bytes = concatMap (map chr . enc . ord)
  where
    enc n
      | n < 0x80 = [n]
      | n < 0x800 = [0xC0 .|. (n `shiftR` 6), cont n]
      | n < 0x10000 = [0xE0 .|. (n `shiftR` 12), cont (n `shiftR` 6), cont n]
      | otherwise = [0xF0 .|. (n `shiftR` 18), cont (n `shiftR` 12), cont (n `shiftR` 6), cont n]
    cont n = 0x80 .|. (n .&. 0x3F)

-- | Order of values: NULL < numbers < TEXT < BLOB; numbers by value across types.
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
