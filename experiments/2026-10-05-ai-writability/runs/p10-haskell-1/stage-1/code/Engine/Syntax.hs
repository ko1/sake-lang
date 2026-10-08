-- | The abstract syntax produced by the parser and consumed by the executor.
module Engine.Syntax
  ( Ident
  , identKey
  , Expr (..)
  , UnOp (..)
  , BinOp (..)
  , ResultCol (..)
  , OrderTerm (..)
  , SelectStmt (..)
  , ColumnDef (..)
  , Stmt (..)
  ) where

import Engine.Value (ColType, Value, asciiLower)

-- | A name spelled as the statement wrote it (quotes removed).
type Ident = String

-- | The case-insensitive key under which a name is looked up.
identKey :: Ident -> String
identKey = asciiLower

data UnOp = Neg | Pos | Not
  deriving (Eq, Show)

data BinOp
  = Add | Sub | Mul | Div | Mod | Concat
  | Eq | Ne | Lt | Le | Gt | Ge | Is | IsNot
  | And | Or
  deriving (Eq, Show)

data Expr
  = ELit Value
  | EColumn (Maybe Ident) Ident -- ^ optional table qualifier, column name
  | EUnary UnOp Expr
  | EBinary BinOp Expr Expr
  | ECall Ident [Expr]
  deriving (Eq, Show)

data ResultCol
  = Star
  | ResultExpr Expr (Maybe Ident) -- ^ expression and its alias

-- | @OrderTerm expr descending nullsFirst@; 'Nothing' means the default placement.
data OrderTerm = OrderTerm Expr Bool (Maybe Bool)

data SelectStmt = SelectStmt
  { selColumns :: [ResultCol]
  , selFrom :: Maybe Ident
  , selWhere :: Maybe Expr
  , selOrderBy :: [OrderTerm]
  , selLimit :: Maybe Expr
  , selOffset :: Maybe Expr
  }

data ColumnDef = ColumnDef Ident ColType

data Stmt
  = CreateTable Bool Ident [ColumnDef] -- ^ IF NOT EXISTS, name, columns
  | DropTable Bool Ident -- ^ IF EXISTS, name
  | Insert Ident (Maybe [Ident]) [[Expr]]
  | Select SelectStmt
