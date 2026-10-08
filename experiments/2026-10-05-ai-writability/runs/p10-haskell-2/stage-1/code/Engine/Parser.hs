-- | Recursive-descent parser: one statement's tokens to a 'Statement' (SPEC 1.4 - 1.8).
-- Any failure is a plain syntax error, so the parser reports no details.
module Engine.Parser
  ( parseStatement
  ) where

import Control.Applicative (Alternative(..), optional)
import Engine.Ast
import Engine.Lexer (Token(..))
import Engine.Names (foldName)
import Engine.Value (ColType(..), Value(VNull, VText))

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
statement = createTable <|> dropTable <|> insert <|> (SelectStmt <$> select)

createTable :: Parser Statement
createTable = do
  keyword "CREATE"
  keyword "TABLE"
  ine <- optional (keyword "IF" *> keyword "NOT" *> keyword "EXISTS")
  name <- identifier
  cols <- parenthesized (commaSep1 columnDef)
  pure (CreateTable (ine /= Nothing) name cols)

columnDef :: Parser ColumnDef
columnDef = ColumnDef <$> identifier <*> typeName

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
eqExpr = chainl1 cmpExpr $
      (Eq <$ (symbol "=" <|> symbol "=="))
  <|> (Ne <$ (symbol "!=" <|> symbol "<>"))
  <|> (IsNot <$ (keyword "IS" *> keyword "NOT"))
  <|> (Is <$ keyword "IS")
cmpExpr = chainl1 addExpr $
      (Lt <$ symbol "<") <|> (Le <$ symbol "<=") <|> (Gt <$ symbol ">") <|> (Ge <$ symbol ">=")
addExpr = chainl1 mulExpr ((Add <$ symbol "+") <|> (Sub <$ symbol "-"))
mulExpr = chainl1 concatExpr ((Mul <$ symbol "*") <|> (Div <$ symbol "/") <|> (Mod <$ symbol "%"))
concatExpr = chainl1 unaryExpr (Concat <$ symbol "||")
unaryExpr = (EUnary Neg <$> (symbol "-" *> unaryExpr))
        <|> (EUnary Plus <$> (symbol "+" *> unaryExpr))
        <|> primary

primary = literal <|> (ELit VNull <$ keyword "NULL") <|> parenthesized expr <|> nameOrCall
  where
    literal = satisfy $ \t -> case t of
      TNumber v -> Just (ELit v)
      TString s -> Just (ELit (VText s))
      _ -> Nothing
    nameOrCall = do
      n <- identifier
      args <- optional (parenthesized (commaSep1 expr <|> pure []))
      pure (maybe (EName n) (ECall n) args)
