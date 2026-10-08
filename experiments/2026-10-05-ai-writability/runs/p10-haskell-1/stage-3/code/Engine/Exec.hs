-- | Execution of one statement against the database: dispatch and DDL.
module Engine.Exec (execute) where

import Engine.Catalog
import Engine.Error
import Engine.Modify (deleteRows, insertRows, updateRows)
import Engine.Schema (buildTable)
import Engine.Select (executeSelect)
import Engine.Syntax

-- | Run a statement: the new database and the lines it prints, or an error
-- (in which case the caller keeps the old database).
execute :: Database -> Stmt -> Result (Database, [String])
execute db stmt = case stmt of
  CreateTable ifNotExists name cols constraints -> createTable db ifNotExists name cols constraints
  DropTable ifExists name -> dropTable db ifExists name
  Insert name cols rows -> insertRows db name cols rows
  Update name sets wher -> updateRows db name sets wher
  Delete name wher -> deleteRows db name wher
  Select sel -> (,) db <$> executeSelect db sel

createTable :: Database -> Bool -> Ident -> [ColumnDef] -> [TableConstraint] -> Result (Database, [String])
createTable db ifNotExists name defs constraints = case findTable name db of
  Just _
    | ifNotExists -> Right (db, [])
    | otherwise -> Left (tableExists name)
  Nothing -> do
    table <- buildTable name defs constraints
    Right (addTable table db, [])

dropTable :: Database -> Bool -> Ident -> Result (Database, [String])
dropTable db ifExists name = case findTable name db of
  Just _ -> Right (removeTable name db, [])
  Nothing
    | ifExists -> Right (db, [])
    | otherwise -> Left (noSuchTable name)
