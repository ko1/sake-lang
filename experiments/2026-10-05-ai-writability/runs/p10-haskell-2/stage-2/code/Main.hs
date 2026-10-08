-- | A small SQL engine: reads a script on standard input, runs it, prints results and errors.
--
-- Layers (each in Engine/): Lexer -> Parser (Ast) -> Exec, which uses Query (SELECT),
-- Expr / Functions (expressions), Catalog (tables and storage rules), Value / Coerce / Real (values).
module Main (main) where

import Engine.Catalog (Database, emptyDatabase)
import Engine.Exec (execute)
import Engine.Lexer (Token, lexScript)
import Engine.Parser (parseStatement)
import System.IO

main :: IO ()
main = do
  hSetEncoding stdin utf8
  hSetEncoding stdout utf8
  script <- getContents
  runScript emptyDatabase (lexScript script)

-- | Run the statements in order; an error prints one line and the script goes on.
runScript :: Database -> [[Token]] -> IO ()
runScript _ [] = pure ()
runScript db (toks : rest) = case parseStatement toks of
  Nothing -> report "syntax error" >> runScript db rest
  Just stmt -> case execute db stmt of
    Left err -> report err >> runScript db rest
    Right (db', ls) -> mapM_ putStrLn ls >> runScript db' rest
  where report msg = putStrLn ("Error: " ++ msg)
