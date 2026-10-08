-- | The abstract syntax produced by the parser and consumed by the executor.
module Engine.Syntax
  ( Ident
  , identKey
  , Expr (..)
  , UnOp (..)
  , BinOp (..)
  , ResultCol (..)
  , OrderTerm (..)
  , childExprs
  , SelectStmt (..)
  , ColumnDef (..)
  , ColumnConstraint (..)
  , TableConstraint (..)
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
  | ECall Ident [Expr] -- ^ @count(*)@ is @ECall "count" []@
  | EAggregate Ident Bool [Expr] [OrderTerm] -- ^ a call written with DISTINCT or ORDER BY: name, distinct, args, order
  | ECase (Maybe Expr) [(Expr, Expr)] (Maybe Expr) -- ^ operand, WHEN/THEN pairs, ELSE
  | EBetween Bool Expr Expr Expr -- ^ negated, x, low, high
  | EIn Bool Expr [Expr] -- ^ negated, x, list
  | ELike Bool Expr Expr -- ^ negated, x, pattern
  | ECast Expr ColType
  deriving (Eq, Show)

data ResultCol
  = Star
  | ResultExpr Expr (Maybe Ident) -- ^ expression and its alias

-- | @OrderTerm expr descending nullsFirst@; 'Nothing' means the default placement.
data OrderTerm = OrderTerm Expr Bool (Maybe Bool)
  deriving (Eq, Show)

data SelectStmt = SelectStmt
  { selDistinct :: Bool
  , selColumns :: [ResultCol]
  , selFrom :: Maybe Ident
  , selWhere :: Maybe Expr
  , selGroupBy :: [Expr]
  , selHaving :: Maybe Expr
  , selOrderBy :: [OrderTerm]
  , selLimit :: Maybe Expr
  , selOffset :: Maybe Expr
  }

data ColumnConstraint
  = CPrimaryKey
  | CNotNull
  | CUnique
  | CDefault Value
  deriving (Eq, Show)

data ColumnDef = ColumnDef Ident ColType [ColumnConstraint]

data TableConstraint
  = TPrimaryKey [Ident]
  | TUnique [Ident]

data Stmt
  = CreateTable Bool Ident [ColumnDef] [TableConstraint] -- ^ IF NOT EXISTS, name, columns, constraints
  | DropTable Bool Ident -- ^ IF EXISTS, name
  | Insert Ident (Maybe [Ident]) [[Expr]]
  | Update Ident [(Ident, Expr)] (Maybe Expr) -- ^ table, assignments, WHERE
  | Delete Ident (Maybe Expr)
  | Select SelectStmt

-- | The direct sub-expressions of an expression, for generic traversals.
childExprs :: Expr -> [Expr]
childExprs e = case e of
  ELit _ -> []
  EColumn _ _ -> []
  EUnary _ a -> [a]
  EBinary _ a b -> [a, b]
  ECall _ args -> args
  EAggregate _ _ args order -> args ++ [x | OrderTerm x _ _ <- order]
  ECase operand branches other ->
    maybe [] pure operand ++ concat [[c, r] | (c, r) <- branches] ++ maybe [] pure other
  EBetween _ x lo hi -> [x, lo, hi]
  EIn _ x es -> x : es
  ELike _ x p -> [x, p]
  ECast x _ -> [x]
