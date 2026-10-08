-- | Recursive-descent parser: one statement's tokens to a 'Statement' (SPEC 1.4 - 1.8).
-- Any failure is a plain syntax error, so the parser reports no details.
module Engine.Parser
  ( parseStatement
  ) where

import Control.Applicative (Alternative(..), optional)
import Engine.Ast
import Engine.Lexer (Token(..))
import Engine.Names (foldName)
import Engine.Value (ColType(..), Value(..))

newtype Parser a = Parser { runParser :: [Token] -> Maybe (a, [Token]) }

instance Functor Parser where
  fmap f (Parser p) = Parser $ \ts -> case p ts of
    Nothing -> Nothing
    Just (a, r) -> Just (f a, r)

instance Applicative Parser where
  pure a = Parser $ \ts -> Just (a, ts)
  Parser pf <*> Parser pa = Parser $ \ts -> case pf ts of
    Nothing -> Nothing
    Just (f, r) -> case pa r of
      Nothing -> Nothing
      Just (a, r') -> Just (f a, r')

instance Monad Parser where
  Parser p >>= f = Parser $ \ts -> case p ts of
    Nothing -> Nothing
    Just (a, r) -> runParser (f a) r

instance Alternative Parser where
  empty = Parser (const Nothing)
  Parser p <|> Parser q = Parser $ \ts -> case p ts of
    Nothing -> q ts
    ok -> ok

-- | Parse the tokens of one statement (without ';'); Nothing is a syntax error.
parseStatement :: [Token] -> Maybe Statement
parseStatement ts = case runParser statement ts of
  Just (st, []) -> Just st
  _ -> Nothing

-- Token primitives ---------------------------------------------------------

satisfy :: (Token -> Maybe a) -> Parser a
satisfy f = Parser $ \ts -> case ts of
  t : r | Just a <- f t -> Just (a, r)
  _ -> Nothing

keyword :: String -> Parser ()
keyword k = satisfy (\t -> if t == TKeyword k then Just () else Nothing)

symbol :: String -> Parser ()
symbol s = satisfy (\t -> if t == TSymbol s then Just () else Nothing)

identifier :: Parser String
identifier = satisfy (\t -> case t of TIdent n -> Just n; _ -> Nothing)

commaSep1 :: Parser a -> Parser [a]
commaSep1 p = (:) <$> p <*> many (symbol "," *> p)

parenthesized :: Parser a -> Parser a
parenthesized p = symbol "(" *> p <* symbol ")"

-- Statements ----------------------------------------------------------------

statement :: Parser Statement
statement = createStatement <|> dropStatement <|> alterTable <|> transaction
        <|> insert Nothing <|> update <|> delete <|> withInsert <|> (SelectStmt <$> select)

createStatement :: Parser Statement
createStatement = keyword "CREATE" *> (createTable <|> createView <|> createIndex)

dropStatement :: Parser Statement
dropStatement = keyword "DROP" *>
      (dropTable <|> (DropView <$> (keyword "VIEW" *> ifExists) <*> identifier)
                 <|> (DropIndex <$> (keyword "INDEX" *> ifExists) <*> identifier))
  where ifExists = (True <$ (keyword "IF" *> keyword "EXISTS")) <|> pure False

ifNotExists :: Parser Bool
ifNotExists = (True <$ (keyword "IF" *> keyword "NOT" *> keyword "EXISTS")) <|> pure False

createTable :: Parser Statement
createTable = do
  keyword "TABLE"
  ine <- ifNotExists
  name <- identifier
  (cols, cons) <- parenthesized $ do
    cols <- commaSep1 columnDef
    cons <- many (symbol "," *> tableConstraint)
    pure (cols, cons)
  pure (CreateTable ine name cols cons)

createView :: Parser Statement
createView = do
  keyword "VIEW"
  ine <- ifNotExists
  name <- identifier
  cols <- option [] (parenthesized (commaSep1 identifier))
  keyword "AS"
  CreateView ine name cols <$> select

createIndex :: Parser Statement
createIndex = do
  unique <- (True <$ keyword "UNIQUE") <|> pure False
  keyword "INDEX"
  ine <- ifNotExists
  name <- identifier
  keyword "ON"
  table <- identifier
  CreateIndex unique ine name table <$> parenthesized (commaSep1 indexedColumn)
  where indexedColumn = IndexedColumn <$> identifier <*> optional collate

-- | COLLATE name; the name is checked when the statement runs.
collate :: Parser String
collate = keyword "COLLATE" *> identifier

alterTable :: Parser Statement
alterTable = do
  keyword "ALTER"
  keyword "TABLE"
  table <- identifier
  AlterTable table <$> (addColumn <|> renameTable <|> renameColumn)
  where
    addColumn = keyword "ADD" *> optional (keyword "COLUMN") *> (AddColumn <$> columnDef)
    renameTable = RenameTable <$> (keyword "RENAME" *> keyword "TO" *> identifier)
    renameColumn = do
      keyword "RENAME"
      _ <- optional (keyword "COLUMN")
      old <- identifier
      keyword "TO"
      RenameColumn old <$> identifier

-- | BEGIN / COMMIT / END / ROLLBACK, each with an optional TRANSACTION.
transaction :: Parser Statement
transaction = kind <* optional (keyword "TRANSACTION")
  where
    kind = (Begin <$ keyword "BEGIN") <|> (Commit <$ (keyword "COMMIT" <|> keyword "END"))
       <|> (Rollback <$ keyword "ROLLBACK")

columnDef :: Parser ColumnDef
columnDef = ColumnDef <$> identifier <*> typeName <*> many columnConstraint

columnConstraint :: Parser ColumnConstraint
columnConstraint =
      (CPrimaryKey <$ (keyword "PRIMARY" *> keyword "KEY"))
  <|> (CNotNull <$ (keyword "NOT" *> keyword "NULL"))
  <|> (CUnique <$ keyword "UNIQUE")
  <|> (CDefault <$> (keyword "DEFAULT" *> defaultValue))
  <|> (CCollate <$> collate)

-- | [+ | -] number, a string, or NULL.
defaultValue :: Parser Value
defaultValue = signed <|> literalValue <|> (VNull <$ keyword "NULL")
  where
    signed = do
      neg <- (False <$ symbol "+") <|> (True <$ symbol "-")
      v <- literalValue
      pure (if neg then negateNumber v else v)
    literalValue = satisfy $ \t -> case t of
      TNumber v -> Just v
      TString s -> Just (VText s)
      _ -> Nothing
    negateNumber (VInt n) = VInt (negate n)
    negateNumber (VReal d) = VReal (negate d)
    negateNumber v = v

tableConstraint :: Parser TableConstraint
tableConstraint =
      (TPrimaryKey <$> (keyword "PRIMARY" *> keyword "KEY" *> parenthesized (commaSep1 identifier)))
  <|> (TUnique <$> (keyword "UNIQUE" *> parenthesized (commaSep1 identifier)))

update :: Parser Statement
update = do
  keyword "UPDATE"
  table <- identifier
  keyword "SET"
  sets <- commaSep1 ((,) <$> identifier <* symbol "=" <*> expr)
  Update table sets <$> optional (keyword "WHERE" *> expr)

delete :: Parser Statement
delete = do
  keyword "DELETE"
  keyword "FROM"
  table <- identifier
  Delete table <$> optional (keyword "WHERE" *> expr)

typeName :: Parser ColType
typeName = satisfy $ \t -> case t of
  TIdent n -> case foldName n of
    "integer" -> Just TInteger
    "real" -> Just TReal
    "text" -> Just TText
    _ -> Nothing
  _ -> Nothing

dropTable :: Parser Statement
dropTable = do
  keyword "TABLE"
  ie <- optional (keyword "IF" *> keyword "EXISTS")
  DropTable (ie /= Nothing) <$> identifier

insert :: Maybe With -> Parser Statement
insert with = do
  keyword "INSERT"
  keyword "INTO"
  table <- identifier
  cols <- optional (parenthesized (commaSep1 identifier))
  source <- (FromValues <$> (keyword "VALUES" *> commaSep1 (parenthesized (commaSep1 expr))))
        <|> (FromQuery <$> select)
  pure (Insert with table cols source)

-- | WITH ... INSERT: the common tables are visible to the INSERT's source.
withInsert :: Parser Statement
withInsert = withClause >>= insert . Just

withClause :: Parser With
withClause = do
  keyword "WITH"
  recursive <- (True <$ keyword "RECURSIVE") <|> pure False
  With recursive <$> commaSep1 cte
  where
    cte = Cte <$> identifier
              <*> option [] (parenthesized (commaSep1 identifier))
              <*> (keyword "AS" *> parenthesized select)

-- | [WITH] simple-select {set-op simple-select} [ORDER BY] [LIMIT [OFFSET]]
select :: Parser Select
select = do
  w <- optional withClause
  first <- simpleSelect
  rest <- many ((,) <$> setOp <*> simpleSelect)
  ord <- optional (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
  lim <- optional (keyword "LIMIT" *> expr)
  off <- case lim of
    Just _ -> optional (keyword "OFFSET" *> expr)
    Nothing -> pure Nothing
  pure (Select w first rest (concat ord) lim off)

setOp :: Parser SetOp
setOp = (keyword "UNION" *> ((UnionAll <$ keyword "ALL") <|> pure Union))
    <|> (Intersect <$ keyword "INTERSECT") <|> (Except <$ keyword "EXCEPT")

simpleSelect :: Parser SimpleSelect
simpleSelect = do
  keyword "SELECT"
  distinct <- (True <$ keyword "DISTINCT") <|> (False <$ optional (keyword "ALL"))
  items <- commaSep1 selectItem
  from <- optional (keyword "FROM" *> fromClause)
  wh <- optional (keyword "WHERE" *> expr)
  groupBy <- option [] (keyword "GROUP" *> keyword "BY" *> commaSep1 expr)
  -- HAVING without GROUP BY is parsed; the query binder decides whether it is allowed (SPEC 3.3)
  having <- optional (keyword "HAVING" *> expr)
  windows <- option [] (keyword "WINDOW" *> commaSep1 ((,) <$> identifier <* keyword "AS" <*> parenthesized windowSpec))
  pure (SimpleSelect distinct items from wh groupBy having windows)

option :: a -> Parser a -> Parser a
option d p = p <|> pure d

selectItem :: Parser SelectItem
selectItem = (Star <$ symbol "*")
         <|> (QualifiedStar <$> identifier <* symbol "." <* symbol "*")
         <|> (Item <$> expr <*> optional alias)

alias :: Parser String
alias = (keyword "AS" *> identifier) <|> identifier

-- FROM ------------------------------------------------------------------------

fromClause :: Parser FromClause
fromClause = FromClause <$> fromItem <*> many joinClause

fromItem :: Parser FromItem
fromItem = (FromTable <$> identifier <*> optional alias)
       <|> (FromSelect <$> parenthesized select <*> optional alias)

-- | ',' and CROSS JOIN take no constraint; a LEFT JOIN needs one; INNER JOIN may have one.
joinClause :: Parser Join
joinClause =
      (symbol "," *> (Join JoinInner <$> fromItem <*> pure NoConstraint))
  <|> (keyword "CROSS" *> keyword "JOIN" *> (Join JoinInner <$> fromItem <*> pure NoConstraint))
  <|> (optional (keyword "INNER") *> keyword "JOIN" *> (Join JoinInner <$> fromItem <*> option NoConstraint constraint))
  <|> (keyword "LEFT" *> optional (keyword "OUTER") *> keyword "JOIN" *> (Join JoinLeft <$> fromItem <*> constraint))
  where
    constraint = (On <$> (keyword "ON" *> expr))
             <|> (Using <$> (keyword "USING" *> parenthesized (commaSep1 identifier)))

orderTerm :: Parser OrderTerm
orderTerm = do
  e <- expr
  dir <- optional ((False <$ keyword "ASC") <|> (True <$ keyword "DESC"))
  nulls <- optional (keyword "NULLS" *> ((NullsFirst <$ keyword "FIRST") <|> (NullsLast <$ keyword "LAST")))
  pure (OrderTerm e (dir == Just True) nulls)

-- Expressions: one function per precedence level, loosest first ----------------

expr :: Parser Expr
expr = orExpr

chainl1 :: Parser Expr -> Parser BinOp -> Parser Expr
chainl1 operand op = operand >>= rest
  where rest l = (do o <- op; r <- operand; rest (EBinary o l r)) <|> pure l

orExpr, andExpr, notExpr, eqExpr, cmpExpr, addExpr, mulExpr, concatExpr, unaryExpr, primary :: Parser Expr
orExpr = chainl1 andExpr (Or <$ keyword "OR")
andExpr = chainl1 notExpr (And <$ keyword "AND")
notExpr = (EUnary Not <$> (keyword "NOT" *> notExpr)) <|> eqExpr
eqExpr = cmpExpr >>= rest
  where
    rest l = (do o <- binaryOp; r <- cmpExpr; rest (EBinary o l r))
         <|> (predicate l >>= rest)
         <|> pure l
    binaryOp =
          (Eq <$ (symbol "=" <|> symbol "=="))
      <|> (Ne <$ (symbol "!=" <|> symbol "<>"))
      <|> (IsNot <$ (keyword "IS" *> keyword "NOT"))
      <|> (Is <$ keyword "IS")
    -- IN, LIKE and BETWEEN, each with an optional NOT in front
    predicate l = do
      neg <- (True <$ keyword "NOT") <|> pure False
      (EInSelect neg l <$> (keyword "IN" *> parenthesized select))
        <|> (EIn neg l <$> (keyword "IN" *> parenthesized (commaSep1 expr)))
        <|> (ELike neg l <$> (keyword "LIKE" *> cmpExpr))
        <|> (do keyword "BETWEEN"
                lo <- cmpExpr
                keyword "AND"
                EBetween neg l lo <$> cmpExpr)
cmpExpr = chainl1 addExpr $
      (Lt <$ symbol "<") <|> (Le <$ symbol "<=") <|> (Gt <$ symbol ">") <|> (Ge <$ symbol ">=")
addExpr = chainl1 mulExpr ((Add <$ symbol "+") <|> (Sub <$ symbol "-"))
mulExpr = chainl1 concatExpr ((Mul <$ symbol "*") <|> (Div <$ symbol "/") <|> (Mod <$ symbol "%"))
concatExpr = chainl1 unaryExpr (Concat <$ symbol "||")
unaryExpr = (EUnary Neg <$> (symbol "-" *> unaryExpr))
        <|> (EUnary Plus <$> (symbol "+" *> unaryExpr))
        <|> collated

-- | A primary with any number of postfix COLLATE; it binds tighter than every binary operator (SPEC 7.2).
collated :: Parser Expr
collated = primary >>= rest
  where rest e = (collate >>= rest . ECollate e) <|> pure e

primary = literal <|> (ELit VNull <$ keyword "NULL") <|> (ESubquery <$> parenthesized select)
      <|> (EExists <$> (keyword "EXISTS" *> parenthesized select)) <|> parenthesized expr <|> caseExpr <|> castExpr <|> nameOrCall
  where
    literal = satisfy $ \t -> case t of
      TNumber v -> Just (ELit v)
      TString s -> Just (ELit (VText s))
      _ -> Nothing
    nameOrCall = do
      n <- identifier
      call <- optional (parenthesized (callArguments n))
      case call of
        Just c -> option c (keyword "OVER" *> overRef >>= windowCall c)
        Nothing -> option (EName n) (EQualified n <$> (symbol "." *> identifier))

-- Window calls (SPEC 6.1) ---------------------------------------------------------

overRef :: Parser WindowRef
overRef = (OverSpec <$> parenthesized windowSpec) <|> (OverName <$> identifier)

-- | The call before OVER becomes a window call; DISTINCT and an inner ORDER BY are not allowed there.
windowCall :: Expr -> WindowRef -> Parser Expr
windowCall (ECall n args) over = pure (EWindow (WindowCall n False args over))
windowCall (EAggCall c) over
  | acStar c = pure (EWindow (WindowCall (acName c) True [] over))
windowCall _ _ = empty

windowSpec :: Parser WindowSpec
windowSpec = WindowSpec
  <$> optional identifier
  <*> option [] (keyword "PARTITION" *> keyword "BY" *> commaSep1 expr)
  <*> option [] (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
  <*> optional frame

frame :: Parser Frame
frame = do
  unit <- (FrameRows <$ keyword "ROWS") <|> (FrameRange <$ keyword "RANGE")
  (start, end) <- (keyword "BETWEEN" *> ((,) <$> bound <* keyword "AND" <*> bound))
              <|> ((\b -> (b, CurrentRow)) <$> bound)
  pure (Frame unit start end)
  where
    bound = (UnboundedPreceding <$ (keyword "UNBOUNDED" *> keyword "PRECEDING"))
        <|> (UnboundedFollowing <$ (keyword "UNBOUNDED" *> keyword "FOLLOWING"))
        <|> (CurrentRow <$ (keyword "CURRENT" *> keyword "ROW"))
        <|> (offset >>= \v -> (OffsetPreceding v <$ keyword "PRECEDING") <|> (OffsetFollowing v <$ keyword "FOLLOWING"))
    offset = (negateNumber <$> (symbol "-" *> number)) <|> (symbol "+" *> number) <|> number
    number = satisfy $ \t -> case t of
      TNumber v -> Just v
      _ -> Nothing
    negateNumber (VInt n) = VInt (negate n)
    negateNumber (VReal d) = VReal (negate d)
    negateNumber v = v

-- | What follows "name(": '*', [DISTINCT] arguments [ORDER BY ...], or nothing.
callArguments :: String -> Parser Expr
callArguments n =
      (EAggCall (AggCall n True False [] []) <$ symbol "*")
  <|> (do distinct <- (True <$ keyword "DISTINCT") <|> pure False
          args <- commaSep1 expr
          order <- option [] (keyword "ORDER" *> keyword "BY" *> (commaSep1 orderTerm))
          pure (if distinct || not (null order)
                  then EAggCall (AggCall n False distinct args order)
                  else ECall n args))
  <|> pure (ECall n [])

caseExpr :: Parser Expr
caseExpr = do
  keyword "CASE"
  operand <- optional expr
  branches <- some ((,) <$> (keyword "WHEN" *> expr) <*> (keyword "THEN" *> expr))
  els <- optional (keyword "ELSE" *> expr)
  keyword "END"
  pure (ECase operand branches els)

castExpr :: Parser Expr
castExpr = do
  keyword "CAST"
  parenthesized (ECast <$> expr <* keyword "AS" <*> typeName)
