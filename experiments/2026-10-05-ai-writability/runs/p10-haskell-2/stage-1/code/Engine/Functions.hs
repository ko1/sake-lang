-- | The scalar function library (SPEC 1.11). To add a function, add one entry to 'functions'.
module Engine.Functions
  ( Function(..)
  , Arity(..)
  , lookupFunction
  , arityAccepts
  ) where

import Data.Char (isAscii, toLower, toUpper)
import qualified Data.Map.Strict as Map
import Engine.Coerce (toNumber)
import Engine.Value

data Arity = Exactly Int | AtLeast Int

data Function = Function
  { fnArity :: Arity
  , fnImpl :: [Value] -> Value
  }

arityAccepts :: Arity -> Int -> Bool
arityAccepts (Exactly n) k = k == n
arityAccepts (AtLeast n) k = k >= n

-- | Look a function up by its folded (lower-case) name.
lookupFunction :: String -> Maybe Function
lookupFunction name = Map.lookup name functions

functions :: Map.Map String Function
functions = Map.fromList
  [ ("length", unary $ \v -> VInt (length (textForm v)))
  , ("upper", unary $ \v -> VText (map asciiUpper (textForm v)))
  , ("lower", unary $ \v -> VText (map asciiLower (textForm v)))
  , ("abs", unary absolute)
  , ("typeof", Function (Exactly 1) $ \args -> case args of
      [v] -> VText (typeOf v)
      _ -> VNull)
  , ("coalesce", Function (AtLeast 2) coalesce)
  , ("ifnull", Function (Exactly 2) coalesce)
  , ("nullif", Function (Exactly 2) $ \args -> case args of
      [x, y] | not (isNull x) && not (isNull y) && compareValues x y == EQ -> VNull
             | otherwise -> x
      _ -> VNull)
  ]

-- | One-argument function that maps NULL to NULL.
unary :: (Value -> Value) -> Function
unary f = Function (Exactly 1) $ \args -> case args of
  [VNull] -> VNull
  [v] -> f v
  _ -> VNull

asciiUpper, asciiLower :: Char -> Char
asciiUpper c = if isAscii c then toUpper c else c
asciiLower c = if isAscii c then toLower c else c

absolute :: Value -> Value
absolute (VInt n) = VInt (abs n)
absolute (VReal d) = VReal (abs d)
absolute v = case toNumber v of
  VInt n -> VReal (abs (fromIntegral n))
  VReal d -> VReal (abs d)
  _ -> VNull

typeOf :: Value -> String
typeOf VNull = "null"
typeOf (VInt _) = "integer"
typeOf (VReal _) = "real"
typeOf (VText _) = "text"

coalesce :: [Value] -> Value
coalesce args = case filter (not . isNull) args of
  v : _ -> v
  [] -> VNull
