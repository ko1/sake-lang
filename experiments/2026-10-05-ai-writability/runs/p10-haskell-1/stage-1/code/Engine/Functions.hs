-- | Built-in scalar functions (SPEC 1.11).
module Engine.Functions (resolveFunction) where

import Data.Maybe (fromMaybe)
import Engine.Error
import Engine.Syntax (Ident, identKey)
import Engine.Value

data Arity = Exactly Int | AtLeast Int

-- | Look a function up by name and check the argument count.
resolveFunction :: Ident -> Int -> Result ([Value] -> Value)
resolveFunction name argc = do
  (arity, impl) <- lookup (identKey name) table `orElse` noSuchFunction name
  if accepts arity then Right impl else Left (wrongArgCount name)
  where
    accepts (Exactly n) = argc == n
    accepts (AtLeast n) = argc >= n

table :: [(String, (Arity, [Value] -> Value))]
table =
  [ ("length", (Exactly 1, nullable1 (\v -> VInt (fromIntegral (length (textForm v))))))
  , ("upper", (Exactly 1, nullable1 (VText . asciiUpper . textForm)))
  , ("lower", (Exactly 1, nullable1 (VText . asciiLower . textForm)))
  , ("abs", (Exactly 1, nullable1 absolute))
  , ("typeof", (Exactly 1, typeOf))
  , ("coalesce", (AtLeast 2, coalesce))
  , ("ifnull", (Exactly 2, coalesce))
  , ("nullif", (Exactly 2, nullIf))
  ]

-- | A one-argument function that maps NULL to NULL.
nullable1 :: (Value -> Value) -> [Value] -> Value
nullable1 _ [VNull] = VNull
nullable1 f [v] = f v
nullable1 _ _ = VNull

typeOf :: [Value] -> Value
typeOf [v] = VText (typeName v)
typeOf _ = VNull

absolute :: Value -> Value
absolute (VInt i) = VInt (abs i)
absolute (VReal d) = VReal (abs d)
absolute (VText s) = case numericPrefix s of
  VInt i -> VReal (abs (fromIntegral i))
  VReal d -> VReal (abs d)
  _ -> VReal 0
absolute v = v

typeName :: Value -> String
typeName VNull = "null"
typeName (VInt _) = "integer"
typeName (VReal _) = "real"
typeName (VText _) = "text"

coalesce :: [Value] -> Value
coalesce args = fromMaybe VNull (lookupFirst args)
  where
    lookupFirst (v : vs) = if v /= VNull then Just v else lookupFirst vs
    lookupFirst [] = Nothing

-- | NULL if the arguments are equal in the order of values (no affinity), else the first.
nullIf :: [Value] -> Value
nullIf [x, y]
  | x /= VNull && y /= VNull && compareValues x y == EQ = VNull
  | otherwise = x
nullIf _ = VNull
