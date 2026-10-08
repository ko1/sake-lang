-- | Name handling shared by every layer: SQL names compare case-insensitively (ASCII only).
module Engine.Names
  ( foldName
  , upperAscii
  , isRowidName
  ) where

import Data.Char (isAscii, toLower, toUpper)

-- | Canonical form of a name, used as the key of every name lookup.
foldName :: String -> String
foldName = map (\c -> if isAscii c then toLower c else c)

upperAscii :: String -> String
upperAscii = map (\c -> if isAscii c then toUpper c else c)

-- | The reserved names of a row's rowid (SPEC 7.1), in any case.
isRowidName :: String -> Bool
isRowidName n = foldName n `elem` ["rowid", "_rowid_", "oid"]
