-- | The five value types of the engine, their text form and their order (SPEC 1.3, 1.9, 7.1, 7.3).
module Engine.Value
  ( Value(..)
  , ColType(..)
  , colTypeName
  , valueTypeName
  , textForm
  , displayForm
  , hexBytes
  , utf8Bytes
  , affinityOfType
  , compareValues
  , isNull
  ) where

import Engine.Real (formatReal)

data Value
  = VNull
  | VInt !Int
  | VReal !Double
  | VText String
  | VBlob String   -- one Char (0..255) per byte, so comparison and length are bytewise
  deriving (Eq, Show)

-- | Declared type of a column. It also acts as the column's affinity.
data ColType = TInteger | TReal | TText | TBlob
  deriving (Eq, Show)

colTypeName :: ColType -> String
colTypeName TInteger = "INTEGER"
colTypeName TReal = "REAL"
colTypeName TText = "TEXT"
colTypeName TBlob = "BLOB"

-- | The affinity a declared type gives (SPEC 7.3): a BLOB column or CAST has none.
affinityOfType :: ColType -> Maybe ColType
affinityOfType TBlob = Nothing
affinityOfType t = Just t

-- | Type name as used in storage errors (SPEC 7.6: 'INT' for an INTEGER value).
valueTypeName :: Value -> String
valueTypeName VNull = "NULL"
valueTypeName (VInt _) = "INT"
valueTypeName (VReal _) = "REAL"
valueTypeName (VText _) = "TEXT"
valueTypeName (VBlob _) = "BLOB"

isNull :: Value -> Bool
isNull VNull = True
isNull _ = False

-- | The text form of a value (SPEC 7.1: a BLOB's bytes read as characters). Results are printed with 'displayForm'.
textForm :: Value -> String
textForm VNull = "NULL"
textForm (VInt n) = show n
textForm (VReal d) = formatReal d
textForm (VText s) = s
textForm (VBlob s) = s

-- | How a result value is printed (SPEC 1.3, 7.1): as 'textForm', except a BLOB is X'HEX'.
displayForm :: Value -> String
displayForm (VBlob s) = "X'" ++ hexBytes s ++ "'"
displayForm v = textForm v

-- | Two uppercase hex digits per byte (each Char of the string is one byte).
hexBytes :: String -> String
hexBytes = concatMap (\c -> let n = fromEnum c in [digit (n `div` 16), digit (n `mod` 16)])
  where digit d = "0123456789ABCDEF" !! d

-- | The UTF-8 bytes of a string, one Char (0..255) per byte; ASCII is unchanged.
utf8Bytes :: String -> String
utf8Bytes = concatMap (map toEnum . encode . fromEnum)
  where
    encode n
      | n < 0x80 = [n]
      | n < 0x800 = [0xC0 + n `div` 64, 0x80 + n `mod` 64]
      | n < 0x10000 = [0xE0 + n `div` 4096, 0x80 + (n `div` 64) `mod` 64, 0x80 + n `mod` 64]
      | otherwise = [0xF0 + n `div` 262144, 0x80 + (n `div` 4096) `mod` 64, 0x80 + (n `div` 64) `mod` 64, 0x80 + n `mod` 64]

-- | Order of values: NULL < numbers < TEXT < BLOB; numbers by value across types, BLOBs bytewise.
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
