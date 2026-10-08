-- | Recursive-descent parser for one statement's tokens (SPEC 1.4 - 1.8).
-- Any failure is a syntax error, so the parser just returns 'Nothing'.
module Engine.Parser (parseStatement) where

import Control.Applicative (Alternative (..), optional)
import Engine.Lexer (Token (..))
import Engine.Syntax
import Engine.Value (ColType (..), Value (..), asciiLower)

newtype Parser a = Parser {runParser :: [Token] -> Maybe (a, [Token])}

instance Functor Parser where
  fmap f (Parser p) = Parser $ \ts -> fmap (\(a, r) -> (f a, r)) (p ts)

instance Applicative Parser where
  pure a = Parser $ \ts -> Just (a, ts)
  Parser pf <*> Parser pa = Parser $ \ts -> case pf ts of
    Nothing -> Nothing
    Just (f, r) -> fmap (\(a, r') -> (f a, r')) (pa r)

instance Monad Parser where
  Parser p >>= f = Parser $ \ts -> case p ts of
    Nothing -> Nothing
    Just (a, r) -> runParser (f a) r

instance Alternative Parser where
  empty = Parser (const Nothing)
  Parser p <|> Parser q = Parser $ \ts -> maybe (q ts) Just (p ts)

-- | Parse the tokens of one statement (without its @;@); the whole input must be used.
parseStatement :: [Token] -> Maybe Stmt
parseStatement ts = case runParser (statement <* eof) ts of
  Just (s, _) -> Just s
  Nothing -> Nothing

-- Primitives -----------------------------------------------------------

satisfy :: (Token -> Maybe a) -> Parser a
satisfy f = Parser $ \ts -> case ts of
  t : r | Just a <- f t -> Just (a, r)
  _ -> Nothing

eof :: Parser ()
eof = Parser $ \ts -> if null ts then Just ((), []) else Nothing

keyword :: String -> Parser ()
keyword k = satisfy (\t -> if t == TKeyword k then Just () else Nothing)

symbol :: String -> Parser ()
symbol s = satisfy (\t -> if t == TSymbol s then Just () else Nothing)

identifier :: Parser Ident
identifier = satisfy (\t -> case t of TIdent s -> Just s; _ -> Nothing)

commaSep1 :: Parser a -> Parser [a]
commaSep1 p = (:) <$> p <*> many (symbol "," *> p)

parens :: Parser a -> Parser a
parens p = symbol "(" *> p <* symbol ")"

-- Statements -----------------------------------------------------------

statement :: Parser Stmt
statement = createTable <|> dropTable <|> insert <|> (Select <$> select)

createTable :: Parser Stmt
createTable = do
  keyword "CREATE"
  keyword "TABLE"
  ifNotExists <- option (keyword "IF" *> keyword "NOT" *> keyword "EXISTS")
  name <- identifier
  cols <- parens (commaSep1 columnDef)
  pure (CreateTable ifNotExists name cols)

columnDef :: Parser ColumnDef
columnDef = ColumnDef <$> identifier <*> columnType

columnType :: Parser ColType
columnType = satisfy $ \t -> case t of
  TIdent s -> case asciiLower s of
    "integer" -> Just CInteger
    "real" -> Just CReal
    "text" -> Just CText
    _ -> Nothing
  _ -> Nothing

dropTable :: Parser Stmt
dropTable = do
  keyword "DROP"
  keyword "TABLE"
  ifExists <- option (keyword "IF" *> keyword "EXISTS")
  DropTable ifExists <$> identifier

insert :: Parser Stmt
insert = do
  keyword "INSERT"
  keyword "INTO"
  table <- identifier
  cols <- optional (parens (commaSep1 identifier))
  keyword "VALUES"
  rows <- commaSep1 (parens (commaSep1 expr))
  pure (Insert table cols rows)

select :: Parser SelectStmt
select = do
  keyword "SELECT"
  cols <- commaSep1 resultCol
  from <- optional (keyword "FROM" *> identifier)
  wher <- optional (keyword "WHERE" *> expr)
  order <- option' [] (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
  limit <- optional (keyword "LIMIT" *> expr)
  offset <- case limit of
    Nothing -> pure Nothing
    Just _ -> optional (keyword "OFFSET" *> expr)
  pure (SelectStmt cols from wher order limit offset)

resultCol :: Parser ResultCol
resultCol = (Star <$ symbol "*") <|> (ResultExpr <$> expr <*> optional alias)
  where
    alias = (optional (keyword "AS") *> identifier)

orderTerm :: Parser OrderTerm
orderTerm = do
  e <- expr
  desc <- (False <$ keyword "ASC") <|> (True <$ keyword "DESC") <|> pure False
  nulls <- optional ((True <$ (keyword "NULLS" *> keyword "FIRST")) <|> (False <$ (keyword "NULLS" *> keyword "LAST")))
  pure (OrderTerm e desc nulls)

-- | True if the optional phrase is present.
option :: Parser a -> Parser Bool
option p = (True <$ p) <|> pure False

option' :: a -> Parser a -> Parser a
option' d p = p <|> pure d

-- Expressions ----------------------------------------------------------
-- One function per precedence level, loosest first (SPEC 1.8).

expr :: Parser Expr
expr = orExpr

chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainl1 p op = p >>= rest
  where
    rest a = (do f <- op; b <- p; rest (f a b)) <|> pure a

binary :: BinOp -> Expr -> Expr -> Expr
binary = EBinary

orExpr, andExpr, notExpr, equality, comparison, additive, multiplicative, concatenation, unary, primary :: Parser Expr
orExpr = chainl1 andExpr (binary Or <$ keyword "OR")
andExpr = chainl1 notExpr (binary And <$ keyword "AND")
notExpr = (EUnary Not <$> (keyword "NOT" *> notExpr)) <|> equality
equality = chainl1 comparison (eqOp <|> isOp)
  where
    eqOp = satisfy $ \t -> case t of
      TSymbol s | s `elem` ["=", "=="] -> Just (binary Eq)
                | s `elem` ["!=", "<>"] -> Just (binary Ne)
      _ -> Nothing
    isOp = keyword "IS" *> ((binary IsNot <$ keyword "NOT") <|> pure (binary Is))
comparison = chainl1 additive (symOp [("<", Lt), ("<=", Le), (">", Gt), (">=", Ge)])
additive = chainl1 multiplicative (symOp [("+", Add), ("-", Sub)])
multiplicative = chainl1 concatenation (symOp [("*", Mul), ("/", Div), ("%", Mod)])
concatenation = chainl1 unary (symOp [("||", Concat)])
unary =
  (EUnary Neg <$> (symbol "-" *> unary))
    <|> (EUnary Pos <$> (symbol "+" *> unary))
    <|> primary

symOp :: [(String, BinOp)] -> Parser (Expr -> Expr -> Expr)
symOp table = satisfy $ \t -> case t of
  TSymbol s -> binary <$> lookup s table
  _ -> Nothing

primary = literal <|> parens expr <|> nameOrCall
  where
    literal = satisfy $ \t -> case t of
      TNumber v -> Just (ELit v)
      TString s -> Just (ELit (VText s))
      TKeyword "NULL" -> Just (ELit VNull)
      _ -> Nothing
    nameOrCall = do
      name <- identifier
      call name <|> qualified name <|> pure (EColumn Nothing name)
    call name = ECall name <$> parens (option' [] (commaSep1 expr))
    qualified table = EColumn (Just table) <$> (symbol "." *> identifier)
