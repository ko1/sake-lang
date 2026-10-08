-- | Recursive-descent parser for one statement's tokens (SPEC 1.4 - 1.8, 2.1 - 2.3).
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
statement = createTable <|> dropTable <|> insert <|> update <|> delete <|> (Select <$> select)

createTable :: Parser Stmt
createTable = do
  keyword "CREATE"
  keyword "TABLE"
  ifNotExists <- option (keyword "IF" *> keyword "NOT" *> keyword "EXISTS")
  name <- identifier
  (cols, constraints) <- parens ((,) <$> commaSep1 columnDef <*> many (symbol "," *> tableConstraint))
  pure (CreateTable ifNotExists name cols constraints)

columnDef :: Parser ColumnDef
columnDef = ColumnDef <$> identifier <*> columnType <*> many columnConstraint

columnConstraint :: Parser ColumnConstraint
columnConstraint =
  (CPrimaryKey <$ (keyword "PRIMARY" *> keyword "KEY"))
    <|> (CNotNull <$ (keyword "NOT" *> keyword "NULL"))
    <|> (CUnique <$ keyword "UNIQUE")
    <|> (CDefault <$> (keyword "DEFAULT" *> defaultValue))

-- | @[+|-] numeric-literal | string-literal | NULL@.
defaultValue :: Parser Value
defaultValue = signed <|> literalValue
  where
    signed = do
      neg <- (False <$ symbol "+") <|> (True <$ symbol "-")
      n <- satisfy (\t -> case t of TNumber v -> Just v; _ -> Nothing)
      pure (if neg then negateNumber n else n)
    negateNumber (VInt i) = VInt (negate i)
    negateNumber (VReal d) = VReal (negate d)
    negateNumber v = v
    literalValue = satisfy $ \t -> case t of
      TNumber v -> Just v
      TString s -> Just (VText s)
      TKeyword "NULL" -> Just VNull
      _ -> Nothing

tableConstraint :: Parser TableConstraint
tableConstraint =
  (TPrimaryKey <$> (keyword "PRIMARY" *> keyword "KEY" *> parens (commaSep1 identifier)))
    <|> (TUnique <$> (keyword "UNIQUE" *> parens (commaSep1 identifier)))

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

update :: Parser Stmt
update = do
  keyword "UPDATE"
  table <- identifier
  keyword "SET"
  sets <- commaSep1 ((,) <$> identifier <* symbol "=" <*> expr)
  wher <- optional (keyword "WHERE" *> expr)
  pure (Update table sets wher)

delete :: Parser Stmt
delete = do
  keyword "DELETE"
  keyword "FROM"
  table <- identifier
  Delete table <$> optional (keyword "WHERE" *> expr)

select :: Parser SelectStmt
select = do
  keyword "SELECT"
  distinct <- (True <$ keyword "DISTINCT") <|> (False <$ keyword "ALL") <|> pure False
  cols <- commaSep1 resultCol
  from <- optional (keyword "FROM" *> identifier)
  wher <- optional (keyword "WHERE" *> expr)
  groupBy <- option' [] (keyword "GROUP" *> keyword "BY" *> commaSep1 expr)
  having <- optional (keyword "HAVING" *> expr)
  order <- option' [] (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
  limit <- optional (keyword "LIMIT" *> expr)
  offset <- case limit of
    Nothing -> pure Nothing
    Just _ -> optional (keyword "OFFSET" *> expr)
  pure (SelectStmt distinct cols from wher groupBy having order limit offset)

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
equality = comparison >>= rest
  where
    rest l = (do f <- infixRhs <|> postfix; rest (f l)) <|> pure l
    infixRhs = do
      op <- eqOp <|> isOp
      r <- comparison
      pure (\l -> op l r)
    eqOp = satisfy $ \t -> case t of
      TSymbol s | s `elem` ["=", "=="] -> Just (binary Eq)
                | s `elem` ["!=", "<>"] -> Just (binary Ne)
      _ -> Nothing
    isOp = keyword "IS" *> ((binary IsNot <$ keyword "NOT") <|> pure (binary Is))
    -- [NOT] BETWEEN / IN / LIKE bind at this level; BETWEEN bounds are one level tighter
    postfix = do
      neg <- option (keyword "NOT")
      between neg <|> inList neg <|> like neg
    between neg = do
      keyword "BETWEEN"
      lo <- comparison
      keyword "AND"
      hi <- comparison
      pure (\l -> EBetween neg l lo hi)
    inList neg = do
      keyword "IN"
      es <- parens (option' [] (commaSep1 expr))
      pure (\l -> EIn neg l es)
    like neg = do
      keyword "LIKE"
      p <- comparison
      pure (\l -> ELike neg l p)
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

primary = literal <|> parens expr <|> caseExpr <|> castExpr <|> nameOrCall
  where
    literal = satisfy $ \t -> case t of
      TNumber v -> Just (ELit v)
      TString s -> Just (ELit (VText s))
      TKeyword "NULL" -> Just (ELit VNull)
      _ -> Nothing
    nameOrCall = do
      name <- identifier
      call name <|> qualified name <|> pure (EColumn Nothing name)
    call name = parens (callArgs name)
    qualified table = EColumn (Just table) <$> (symbol "." *> identifier)

-- | Inside the parentheses of a call: @*@, nothing, or
-- @[DISTINCT] expr, ... [ORDER BY term, ...]@ (SPEC 3.1).
callArgs :: Ident -> Parser Expr
callArgs name = (ECall name [] <$ symbol "*") <|> plain <|> withModifiers
  where
    plain = ECall name <$> (commaSep1 expr <* peekClose) <|> (ECall name [] <$ peekClose)
    withModifiers = do
      distinct <- option (keyword "DISTINCT")
      args <- commaSep1 expr
      order <- option' [] (keyword "ORDER" *> keyword "BY" *> commaSep1 orderTerm)
      pure (EAggregate name distinct args order)
    peekClose = Parser $ \ts -> case ts of
      TSymbol ")" : _ -> Just ((), ts)
      _ -> Nothing

caseExpr :: Parser Expr
caseExpr = do
  keyword "CASE"
  operand <- optional (notWhen *> expr)
  branches <- some ((,) <$> (keyword "WHEN" *> expr) <*> (keyword "THEN" *> expr))
  other <- optional (keyword "ELSE" *> expr)
  keyword "END"
  pure (ECase operand branches other)
  where
    notWhen = Parser $ \ts -> case ts of
      TKeyword "WHEN" : _ -> Nothing
      _ -> Just ((), ts)

castExpr :: Parser Expr
castExpr = do
  keyword "CAST"
  parens (ECast <$> expr <* keyword "AS" <*> columnType)
