-- | A script's state: the database and the open transaction, if any (SPEC 5.5).
-- The database is a value, so a transaction is the database as it was at BEGIN.
module Engine.Session
  ( Session
  , newSession
  , runStatement
  ) where

import Engine.Ast (Statement(..))
import Engine.Catalog (Database, emptyDatabase)
import Engine.Exec (execute)

data Session = Session
  { sessionDb :: Database
  , sessionSnapshot :: Maybe Database   -- the database at BEGIN while a transaction is open
  }

newSession :: Session
newSession = Session emptyDatabase Nothing

-- | The session after the statement and the lines to print, or an error (the session is then unchanged).
runStatement :: Session -> Statement -> Either String (Session, [String])
runStatement s stmt = case stmt of
  Begin -> case sessionSnapshot s of
    Nothing -> Right (s { sessionSnapshot = Just (sessionDb s) }, [])
    Just _ -> Left "cannot start a transaction within a transaction"
  Commit -> case sessionSnapshot s of
    Just _ -> Right (s { sessionSnapshot = Nothing }, [])
    Nothing -> Left "cannot commit - no transaction is active"
  Rollback -> case sessionSnapshot s of
    Just before -> Right (Session before Nothing, [])
    Nothing -> Left "cannot rollback - no transaction is active"
  _ -> (\(db, out) -> (s { sessionDb = db }, out)) <$> execute (sessionDb s) stmt
