-- | Turns the script text into tokens and cuts it into statements (SPEC 1.2).
module Engine.Lexer
  ( Token(..)
  , lexScript
  ) where

import Data.Char (isAscii, isAlpha, isAlphaNum, isDigit)
import qualified Data.Set as Set
import Engine.Coerce (scanNumber)
import Engine.Names (upperAscii)
import Engine.Value (Value)

data Token
  = TKeyword String      -- upper-cased
  | TIdent String        -- as written (quotes removed)
  | TNumber Value
  | TString String
  | TSymbol String
  | TBad                 -- a character or literal the language does not have
  deriving (Eq, Show)

-- | Split a script into statements; each is its tokens without the closing ';'.
-- Empty statements are dropped.
lexScript :: String -> [[Token]]
lexScript = filter (not . null) . splitStatements . tokenize

splitStatements :: [Token] -> [[Token]]
splitStatements ts = case break (== TSymbol ";") ts of
  (stmt, []) -> [stmt]
  (stmt, _ : rest) -> stmt : splitStatements rest

tokenize :: String -> [Token]
tokenize [] = []
tokenize s@(c : cs)
  | isWs c = tokenize cs
  | c == '-', ('-' : r) <- cs = tokenize (dropWhile (/= '\n') r)
  | c == '/', ('*' : r) <- cs = tokenize (skipBlockComment r)
  | c == '\'' = quoted '\'' TString cs
  | c == '"' = quoted '"' TIdent cs
  | isIdentStart c =
      let (word, rest) = span isIdentChar s
          up = upperAscii word
      in (if Set.member up keywords then TKeyword up else TIdent word) : tokenize rest
  | isDigit c || (c == '.' && startsWithDigit cs) = case scanNumber s of
      Just (v, rest) -> TNumber v : tokenize rest
      Nothing -> TBad : tokenize cs
  | otherwise = case s of
      a : b : rest | [a, b] `elem` twoCharOps -> TSymbol [a, b] : tokenize rest
      _ | c `elem` "+-*/%=<>(),;." -> TSymbol [c] : tokenize cs
        | otherwise -> TBad : tokenize cs
  where
    startsWithDigit (d : _) = isDigit d
    startsWithDigit [] = False

isWs :: Char -> Bool
isWs c = c == ' ' || c == '\t' || c == '\n' || c == '\r'

isIdentStart, isIdentChar :: Char -> Bool
isIdentStart c = c == '_' || (isAscii c && isAlpha c)
isIdentChar c = c == '_' || (isAscii c && isAlphaNum c)

twoCharOps :: [String]
twoCharOps = ["||", "==", "!=", "<>", "<=", ">="]

skipBlockComment :: String -> String
skipBlockComment ('*' : '/' : r) = r
skipBlockComment (_ : r) = skipBlockComment r
skipBlockComment [] = []

-- | A literal closed by the quote character, where a doubled quote stands for one.
-- An unterminated literal swallows the rest of the script as one bad token.
quoted :: Char -> (String -> Token) -> String -> [Token]
quoted q mk = go []
  where
    go acc (a : b : r) | a == q && b == q = go (q : acc) r
    go acc (a : r)
      | a == q = mk (reverse acc) : tokenize r
      | otherwise = go (a : acc) r
    go _ [] = [TBad]

keywords :: Set.Set String
keywords = Set.fromList (words
  "ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE \
  \CROSS CURRENT DEFAULT DELETE DESC DISTINCT DROP ELSE END ESCAPE EXCEPT EXISTS FIRST FOLLOWING FROM GLOB GROUP \
  \HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET \
  \ON OR ORDER OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT \
  \SET TABLE THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW \
  \WITH")
