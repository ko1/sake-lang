-- | A failure found while a statement's values are computed (SPEC 7.3). Values are computed lazily
-- and without an error channel, so it is thrown and caught per statement in Main (see 'Engine.Session.settle').
module Engine.Failure
  ( SqlFailure(..)
  , failSql
  ) where

import Control.Exception (Exception, throw)

newtype SqlFailure = SqlFailure String
  deriving (Show)

instance Exception SqlFailure

failSql :: String -> a
failSql = throw . SqlFailure
