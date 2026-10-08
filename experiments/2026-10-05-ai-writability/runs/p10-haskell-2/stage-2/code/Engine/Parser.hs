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
statement = createTable <|> dropTable <|> insert <|> update <|> delete <|> (SelectStmt <$> select)

createTable :: Parser Statement
createTable = do
  keyword "CREATE"
  keyword "TABLE"
  ine <- optional (keyword "IF" *> keyword "NOT" *> keyword "EXISTS")
  name <- identifier
  (cols, cons) <- parenthesized $ do
    cols <- commaSep1 columnDef
    cons <- many (symbol "," *> tableConstraint)
    pure (cols, cons)
  pure (CreateTable (ine /= Nothing) name cols cons)

columnDef :: Parser ColumnDef
columnDef = ColumnDef <$> identifier <*> typeName <*> many columnConstraint

columnConstraint :: Parser ColumnConstraint
columnConstraint =
      (CPrimaryKey <$ (keyword "PRIMARY" *> keyword "KEY"))
  <|> (CNotNull <$ (keyword "NOT" *> keyword "NULL"))
  <|> (CUnique <$ keyword "UNIQUE")
  <|> (CDefault <$> (keyword "DEFAULT" *> defaultValue))

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
  keyword "DROP"
  keyword "TABLE"
  ie <- optional (keyword "IF" *> keyword "EXISTS")
  DropTable (ie /= Nothing) <$> identifier

insert :: Parser Statement
insert = do
  keyword "INSERT"
  keyword "INTO"
  table <- identifier
  cols <- optional (parenthesized (commaSep1 identifier))
  keyword "VALUES"
  rows <- commaSep1 (parenthesized (commaSep1 expr))
  pure (Insert table cols rows)

select :: Parser Select
select = do
  keyword "SELECT"
  items <- commaSep1 selectItem
  from <- optional (keyword "FROM" *> identifier)
  wh <- optional (keyword "WHERE" *> expr)
  ord <- optional (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
  lim <- optional (keyword "LIMIT" *> expr)
  off <- case lim of
    Just _ -> optional (keyword "OFFSET" *> expr)
    Nothing -> pure Nothing
  pure (Select items from wh (concat ord) lim off)

selectItem :: Parser SelectItem
selectItem = (Star <$ symbol "*") <|> (Item <$> expr <*> optional alias)
  where alias = (keyword "AS" *> identifier) <|> identifier

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
      (EIn neg l <$> (keyword "IN" *> parenthesized (commaSep1 expr)))
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
        <|> primary

primary = literal <|> (ELit VNull <$ keyword "NULL") <|> parenthesized expr <|> caseExpr <|> castExpr <|> nameOrCall
  where
    literal = satisfy $ \t -> case t of
      TNumber v -> Just (ELit v)
      TString s -> Just (ELit (VText s))
      _ -> Nothing
    nameOrCall = do
      n <- identifier
      args <- optional (parenthesized (commaSep1 expr <|> pure []))
      pure (maybe (EName n) (ECall n) args)

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
