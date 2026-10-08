-- | Turns script text into tokens and cuts the token stream into statements (SPEC 1.2).
module Engine.Lexer
  ( Token (..)
  , tokenize
  , splitStatements
  ) where

import Data.Char (chr, digitToInt, isAlpha, isAlphaNum, isAscii, isDigit, isHexDigit)
import Engine.Value (Value, asciiUpper, scanNumber)

data Token
  = TKeyword String -- ^ upper-cased keyword
  | TIdent String -- ^ identifier as written (quotes removed)
  | TNumber Value
  | TString String
  | TBlob String -- ^ the bytes of a blob literal, one 'Char' per byte
  | TSymbol String
  | TSemi
  | TBad -- ^ anything the grammar cannot use; always a syntax error
  deriving (Eq, Show)

keywords :: [String]
keywords = words
  "ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE \
  \CROSS CURRENT DEFAULT DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP \
  \HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET \
  \ON OR ORDER OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT \
  \SET TABLE THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW \
  \WITH"

isIdentStart, isIdentChar :: Char -> Bool
isIdentStart c = isAscii c && (isAlpha c || c == '_')
isIdentChar c = isAscii c && (isAlphaNum c || c == '_')

tokenize :: String -> [Token]
tokenize [] = []
tokenize s@(c : rest)
  | c `elem` " \t\n\r" = tokenize rest
  | c == '-', ('-' : r) <- rest = tokenize (dropWhile (/= '\n') r)
  | c == '/', ('*' : r) <- rest = tokenize (skipBlockComment r)
  | c == ';' = TSemi : tokenize rest
  | c == '\'' = quoted '\'' TString rest
  | c == '"' = quoted '"' TIdent rest
  | c `elem` "xX", ('\'' : r) <- rest = blobLiteral r
  | isDigit c || (c == '.' && startsWithDigit rest) = number s
  | isIdentStart c =
      let (name, r) = span isIdentChar s
          up = asciiUpper name
       in (if up `elem` keywords then TKeyword up else TIdent name) : tokenize r
  | otherwise = case s of
      _ | Just (sym, r) <- twoChar s -> TSymbol sym : tokenize r
      _ | c `elem` "+-*/%=<>(),." -> TSymbol [c] : tokenize rest
      _ -> TBad : tokenize rest
  where
    startsWithDigit (d : _) = isDigit d
    startsWithDigit [] = False

twoChar :: String -> Maybe (String, String)
twoChar (a : b : r)
  | [a, b] `elem` ["||", "<=", ">=", "<>", "!=", "=="] = Just ([a, b], r)
twoChar _ = Nothing

skipBlockComment :: String -> String
skipBlockComment ('*' : '/' : r) = r
skipBlockComment (_ : r) = skipBlockComment r
skipBlockComment [] = []

-- | A literal in quotes where the quote doubled stands for itself.
-- An unterminated one swallows the rest of the script as a bad token.
quoted :: Char -> (String -> Token) -> String -> [Token]
quoted q mk = go []
  where
    go acc (a : b : r) | a == q && b == q = go (q : acc) r
    go acc (a : r)
      | a == q = mk (reverse acc) : tokenize r
      | otherwise = go (a : acc) r
    go _ [] = [TBad]

-- | The rest of @X'...'@ after the opening quote. The literal always ends at the next
-- quote (so a @;@ inside never ends a statement); a malformed one is a bad token.
blobLiteral :: String -> [Token]
blobLiteral r = case break (== '\'') r of
  (digits, '\'' : after)
    | all isHexDigit digits, even (length digits) -> TBlob (bytes digits) : tokenize after
    | otherwise -> TBad : tokenize after
  (_, []) -> [TBad]
  where
    bytes (a : b : more) = chr (digitToInt a * 16 + digitToInt b) : bytes more
    bytes _ = []

-- | A numeric literal; letters stuck to it make the token bad (@12abc@).
number :: String -> [Token]
number s = case scanNumber s of
  Just (_, r@(c : _)) | isIdentChar c -> TBad : tokenize (dropWhile isIdentChar r)
  Just (v, r) -> TNumber v : tokenize r
  Nothing -> TBad : tokenize (drop 1 s)

-- | Statements are the token runs between semicolons; empty ones are dropped.
-- Text after the last semicolon (not expected) is kept as a statement.
splitStatements :: [Token] -> [[Token]]
splitStatements ts = case break (== TSemi) ts of
  (stmt, rest) ->
    [stmt | not (null stmt)] ++ case rest of
      _ : more -> splitStatements more
      [] -> []
