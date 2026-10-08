-- | Syntax trees produced by the parser and consumed by the executor.
-- Names are kept as the statement wrote them (error messages spell them so).
module Engine.Ast
  ( Statement(..)
  , ColumnDef(..)
  , ColumnConstraint(..)
  , TableConstraint(..)
  , Select(..)
  , SelectItem(..)
  , OrderTerm(..)
  , NullsPos(..)
  , Expr(..)
  , UnOp(..)
  , BinOp(..)
  ) where

import Engine.Value (ColType, Value)

data Statement
  = CreateTable
      { ctIfNotExists :: Bool, ctName :: String
      , ctColumns :: [ColumnDef], ctConstraints :: [TableConstraint] }
  | DropTable { dtIfExists :: Bool, dtName :: String }
  | Insert { insTable :: String, insColumns :: Maybe [String], insRows :: [[Expr]] }
  | Update { updTable :: String, updSet :: [(String, Expr)], updWhere :: Maybe Expr }
  | Delete { delTable :: String, delWhere :: Maybe Expr }
  | SelectStmt Select
  deriving (Show)

data ColumnDef = ColumnDef { cdName :: String, cdType :: ColType, cdConstraints :: [ColumnConstraint] }
  deriving (Show)

data ColumnConstraint
  = CPrimaryKey
  | CNotNull
  | CUnique
  | CDefault Value
  deriving (Show)

-- | Constraints written after the column definitions; the names are as written.
data TableConstraint
  = TPrimaryKey [String]
  | TUnique [String]
  deriving (Show)

data Select = Select
  { selItems :: [SelectItem]
  , selFrom :: Maybe String
  , selWhere :: Maybe Expr
  , selOrderBy :: [OrderTerm]
  , selLimit :: Maybe Expr
  , selOffset :: Maybe Expr
  } deriving (Show)

data SelectItem
  = Star
  | Item Expr (Maybe String)   -- expression and optional alias
  deriving (Show)

data NullsPos = NullsFirst | NullsLast
  deriving (Eq, Show)

data OrderTerm = OrderTerm
  { otExpr :: Expr
  , otDesc :: Bool
  , otNulls :: Maybe NullsPos
  } deriving (Show)

data Expr
  = ELit Value
  | EName String
  | ECall String [Expr]
  | EUnary UnOp Expr
  | EBinary BinOp Expr Expr
  | ECase (Maybe Expr) [(Expr, Expr)] (Maybe Expr)   -- operand, (WHEN, THEN) pairs, ELSE
  | EBetween Bool Expr Expr Expr                      -- negated?, x, low, high
  | EIn Bool Expr [Expr]                              -- negated?, x, list
  | ELike Bool Expr Expr                              -- negated?, x, pattern
  | ECast Expr ColType
  deriving (Show)

data UnOp = Neg | Plus | Not
  deriving (Eq, Show)

data BinOp
  = Add | Sub | Mul | Div | Mod
  | Concat
  | Eq | Ne | Lt | Le | Gt | Ge
  | Is | IsNot
  | And | Or
  deriving (Eq, Show)
