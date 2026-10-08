-- | Execution of one statement against the database: dispatch, and transactions.
module Engine.Exec (execute) where

import Control.Exception (catch, evaluate)
import System.IO.Unsafe (unsafePerformIO)
import Engine.Catalog
import Engine.Ddl
import Engine.Error
import Engine.Modify (deleteRows, insertRows, updateRows)
import Engine.Query (executeQuery)
import Engine.Syntax

-- | Run a statement: the new database and the lines it prints, or an error
-- (in which case the caller keeps the old database).
execute :: Database -> Stmt -> Result (Database, [String])
execute db stmt = case stmt of
  CreateTable ifNotExists name cols constraints -> silently (createTable db ifNotExists name cols constraints)
  DropTable ifExists name -> silently (dropTable db ifExists name)
  CreateView ifNotExists name cols query -> silently (createView db ifNotExists name cols query)
  DropView ifExists name -> silently (dropView db ifExists name)
  CreateIndex unique ifNotExists name table cols -> silently (createIndex db unique ifNotExists name table cols)
  DropIndex ifExists name -> silently (dropIndex db ifExists name)
  AlterAddColumn table def -> settled table (silently (alterAddColumn db table def))
  AlterRenameTable table new -> silently (alterRenameTable db table new)
  AlterRenameColumn table old new -> silently (alterRenameColumn db table old new)
  Insert name cols source -> settled name (insertRows db name cols source)
  Update name sets wher -> settled name (updateRows db name sets wher)
  Delete name wher -> settled name (deleteRows db name wher)
  Select query -> settled "" ((,) db <$> executeQuery db query)
  Begin
    | inTransaction db -> Left transactionActive
    | otherwise -> Right (beginTransaction db, [])
  Commit
    | inTransaction db -> Right (commitTransaction db, [])
    | otherwise -> Left (noTransaction "commit")
  Rollback
    | inTransaction db -> Right (rollbackTransaction db, [])
    | otherwise -> Left (noTransaction "rollback")
  where
    silently = fmap (\db' -> (db', []))

-- | Force an outcome now. A subquery that fails while it runs (an integer
-- overflow) throws 'SqlFailure' from inside lazy values; that is the
-- statement's error, whichever statement later happens to read the value.
settled :: Ident -> Result (Database, [String]) -> Result (Database, [String])
settled table outcome = unsafePerformIO $
  (evaluate (forced outcome) >> pure outcome) `catch` \(SqlFailure e) -> pure (Left e)
  where
    forced (Right (db', out)) = forceRows table db' `seq` length (concat out) `seq` ()
    forced (Left _) = ()
{-# NOINLINE settled #-}
