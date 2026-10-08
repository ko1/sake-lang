-- | A small SQL engine: reads a script on standard input, runs it, prints results and errors.
--
-- Layers (each in Engine/): Lexer -> Parser (Ast) -> Session (transactions) -> Exec, which uses Schema / Alter (DDL),
-- Modify (INSERT, UPDATE, DELETE), Query (SELECT, compounds, WITH; SetOps, Recursive),
-- Expr / Functions (expressions), Catalog (tables and storage rules), Value / Coerce / Real (values).
module Main (main) where

import Engine.Lexer (Token, lexScript)
import Engine.Parser (parseStatement)
import Control.Exception (evaluate, try)
import Engine.Failure (SqlFailure(..))
import Engine.Session (Session, newSession, runStatement, settle)
import System.IO

main :: IO ()
main = do
  hSetEncoding stdin utf8
  hSetEncoding stdout utf8
  script <- getContents
  runScript newSession (lexScript script)

-- | Run the statements in order; an error prints one line and the script goes on.
runScript :: Session -> [[Token]] -> IO ()
runScript _ [] = pure ()
runScript db (toks : rest) = case parseStatement toks of
  Nothing -> report "syntax error" >> runScript db rest
  Just stmt -> do
    outcome <- try (evaluate (settle (runStatement db stmt)))
    case outcome of
      Left (SqlFailure msg) -> report msg >> runScript db rest
      Right (Left err) -> report err >> runScript db rest
      Right (Right (db', ls)) -> mapM_ putStrLn ls >> runScript db' rest
  where report msg = putStrLn ("Error: " ++ msg)
