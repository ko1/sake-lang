-- | Running a whole script: split into statements, parse, execute, print.
module Engine.Run (runScript) where

import Engine.Catalog (Database, emptyDatabase)
import Engine.Error (SqlError (..))
import Engine.Exec (execute)
import Engine.Lexer (Token, splitStatements, tokenize)
import Engine.Parser (parseStatement)

-- | The output lines of a script. Lazy: lines appear as statements finish.
runScript :: String -> [String]
runScript = go emptyDatabase . splitStatements . tokenize
  where
    go :: Database -> [[Token]] -> [String]
    go _ [] = []
    go db (toks : rest) = case parseStatement toks of
      Nothing -> errorLine "syntax error" : go db rest
      Just stmt -> case execute db stmt of
        Left (SqlError msg) -> errorLine msg : go db rest
        Right (db', out) -> out ++ go db' rest
    errorLine msg = "Error: " ++ msg
