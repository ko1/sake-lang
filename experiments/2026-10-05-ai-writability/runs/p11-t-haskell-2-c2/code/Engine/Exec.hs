-- | Executes one statement against the database (SPEC 1.4, 2.1, 5): schema changes in Engine.Schema and
-- Engine.Alter, row changes in Engine.Modify, queries in Engine.Query. A failing statement changes nothing.
module Engine.Exec
  ( execute
  ) where

import Data.List (intercalate)
import Engine.Alter (alterTable)
import Engine.Ast
import Engine.Catalog
import Engine.Modify
import Engine.Query (runSelect)
import Engine.Schema
import Engine.Value

-- | The new database and the lines to print, or an error message. Transaction statements are
-- handled by "Engine.Session", which owns the state they need.
execute :: Database -> Statement -> Either String (Database, [String])
execute db stmt = case stmt of
  CreateTable ine name cols cons -> done <$> createTable db ine name cols cons
  DropTable ie name -> done <$> dropTable db ie name
  CreateView ine name cols sel -> done <$> createView db ine name cols sel
  DropView ie name -> done <$> dropView db ie name
  CreateIndex unique ine name table cols -> done <$> createIndex db unique ine name table cols
  DropIndex ie name -> done <$> dropIndex db ie name
  AlterTable name action -> done <$> alterTable db name action
  Insert with name cols source -> done <$> insertRows db with name cols source
  Update name sets wh -> done <$> updateRows db name sets wh
  Delete name wh -> done <$> deleteRows db name wh
  SelectStmt sel -> (\rows -> (db, map (joinBar . map displayForm) rows)) <$> runSelect db sel
  Begin -> Left "transaction statement outside a session"
  Commit -> Left "transaction statement outside a session"
  Rollback -> Left "transaction statement outside a session"
  where
    joinBar = intercalate "|"
    done db' = (db', [])
