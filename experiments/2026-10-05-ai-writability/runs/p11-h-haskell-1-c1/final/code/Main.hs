-- | Entry point: read a SQL script from standard input, run it, print the results.
module Main (main) where

import Engine.Run (runScript)
import System.IO

main :: IO ()
main = do
  enc <- mkTextEncoding "UTF-8//ROUNDTRIP"
  hSetEncoding stdin enc
  hSetEncoding stdout enc
  hSetBuffering stdout (BlockBuffering Nothing)
  input <- getContents
  mapM_ putStrLn (runScript input)
