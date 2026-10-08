-- | Executes one statement against the database (SPEC 1.4, 2.1): schema changes here, row changes in Engine.Modify, queries in Engine.Query. A failing statement changes nothing.
module Engine.Exec
  ( execute
  ) where

import Data.List (intercalate)
import Engine.Ast
import Engine.Catalog
import Engine.Modify
import Engine.Query (runSelect)
import Engine.Value

-- | The new database and the lines to print, or an error message.
execute :: Database -> Statement -> Either String (Database, [String])
execute db stmt = case stmt of
  CreateTable ine name cols cons -> createTable db ine name cols cons
  DropTable ie name -> dropTable db ie name
  Insert name cols rows -> done <$> insertRows db name cols rows
  Update name sets wh -> done <$> updateRows db name sets wh
  Delete name wh -> done <$> deleteRows db name wh
  SelectStmt sel -> (\rows -> (db, map (joinBar . map textForm) rows)) <$> runSelect db sel
  where
    joinBar = intercalate "|"
    done db' = (db', [])

createTable :: Database -> Bool -> String -> [ColumnDef] -> [TableConstraint] -> Either String (Database, [String])
createTable db ifNotExists name defs cons = case lookupTable name db of
  Just _ | ifNotExists -> Right (db, [])
         | otherwise -> Left ("table " ++ name ++ " already exists")
  Nothing -> (\t -> (insertTable t db, [])) <$> newTable name defs cons

dropTable :: Database -> Bool -> String -> Either String (Database, [String])
dropTable db ifExists name = case lookupTable name db of
  Just _ -> Right (removeTable name db, [])
  Nothing | ifExists -> Right (db, [])
          | otherwise -> Left ("no such table: " ++ name)
