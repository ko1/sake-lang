-- | Turning a @CREATE TABLE@ definition into a 'Table': column properties,
-- the INTEGER PRIMARY KEY and the list of uniqueness constraints (SPEC 1.4, 2.1).
module Engine.Schema (buildTable, makeColumn) where

import Data.List (findIndex)
import qualified Data.Sequence as Seq
import Engine.Catalog (Column (..), Table (..), UniqueKey (..))
import Engine.Error
import Engine.Syntax
import Engine.Value

-- | Build an empty table; fails on a duplicate column or an unknown column in a table constraint.
buildTable :: Ident -> [ColumnDef] -> [TableConstraint] -> Result Table
buildTable name defs constraints = do
  checkDuplicates [] defs
  columns <- mapM makeColumn defs
  let resolve n =
        findIndex (\c -> identKey (columnName c) == identKey n) columns
          `orElse` noSuchColumn n
  keyed <- mapM (\(ns, isPk) -> (,) <$> mapM resolve ns <*> pure isPk) groups
  let pkColumns = concat [cs | (cs, True) <- keyed]
      rowKey = case pkColumns of
        [i] | columnType (columns !! i) == CInteger -> Just i
        _ -> Nothing
      -- the row key is enforced by 'tableRowKey', not as an ordinary uniqueness constraint
      uniques = [UniqueKey cs [columnCollation (columns !! i) | i <- cs] Nothing | (cs, isPk) <- keyed, not (isPk && rowKey /= Nothing)]
      notNull i c = c {columnNotNull = columnNotNull c || i `elem` pkColumns}
  Right (Table name (zipWith notNull [0 ..] columns) Seq.empty rowKey uniques)
  where
    -- constraint column lists in declaration order (column constraints, then table constraints)
    groups =
      [ ([n], isPk)
      | ColumnDef n _ cs <- defs, c <- cs, Just isPk <- [keyKind c]
      ]
        ++ [(ns, isPk) | tc <- constraints, let (ns, isPk) = tableKind tc]
    keyKind CPrimaryKey = Just True
    keyKind CUnique = Just False
    keyKind _ = Nothing
    tableKind (TPrimaryKey ns) = (ns, True)
    tableKind (TUnique ns) = (ns, False)
    checkDuplicates _ [] = Right ()
    checkDuplicates seen (ColumnDef n _ _ : rest)
      | identKey n `elem` seen = Left (duplicateColumn n)
      | otherwise = checkDuplicates (identKey n : seen) rest

-- | A column as declared (the key constraints are handled by the table);
-- fails on an unknown collation name.
makeColumn :: ColumnDef -> Result Column
makeColumn (ColumnDef n t cs) = do
  collation <- case [c | CCollate c <- cs] of
    c : _ -> collationNamed c
    [] -> Right Binary
  Right (Column n t (CNotNull `elem` cs) defaultValue collation)
  where
    defaultValue = case [v | CDefault v <- cs] of
      v : _ -> v
      [] -> VNull
