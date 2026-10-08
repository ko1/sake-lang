-- | The abstract syntax produced by the parser and consumed by the executor.
module Engine.Syntax
  ( Ident
  , identKey
  , Expr (..)
  , UnOp (..)
  , BinOp (..)
  , ResultCol (..)
  , FromClause (..)
  , FromItem (..)
  , Join (..)
  , JoinKind (..)
  , JoinConstraint (..)
  , OrderTerm (..)
  , childExprs
  , SelectStmt (..)
  , Query (..)
  , QueryBody (..)
  , CompoundTail (..)
  , SetOp (..)
  , With (..)
  , Cte (..)
  , InsertSource (..)
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
  | ESubquery Query -- ^ a scalar subquery
  | EExists Query
  | EInSelect Bool Expr Query -- ^ negated, x, subquery
  deriving (Eq, Show)

data ResultCol
  = Star
  | TableStar Ident -- ^ @q.*@
  | ResultExpr Expr (Maybe Ident) -- ^ expression and its alias
  deriving (Eq, Show)

-- | @FROM item [join item [constraint]]...@, joins associating to the left (SPEC 4.1).
data FromClause = FromClause FromItem [Join]
  deriving (Eq, Show)

data FromItem
  = FromTable Ident (Maybe Ident) -- ^ table, alias
  | FromSubquery Query (Maybe Ident) -- ^ subquery, alias
  deriving (Eq, Show)

data JoinKind = CrossJoin | InnerJoin | LeftJoin
  deriving (Eq, Show)

data JoinConstraint = NoConstraint | On Expr | Using [Ident]
  deriving (Eq, Show)

data Join = Join JoinKind FromItem JoinConstraint
  deriving (Eq, Show)

-- | @OrderTerm expr descending nullsFirst@; 'Nothing' means the default placement.
data OrderTerm = OrderTerm Expr Bool (Maybe Bool)
  deriving (Eq, Show)

data SelectStmt = SelectStmt
  { selDistinct :: Bool
  , selColumns :: [ResultCol]
  , selFrom :: Maybe FromClause
  , selWhere :: Maybe Expr
  , selGroupBy :: [Expr]
  , selHaving :: Maybe Expr
  , selOrderBy :: [OrderTerm]
  , selLimit :: Maybe Expr
  , selOffset :: Maybe Expr
  } deriving (Eq, Show)

data SetOp = UnionAll | Union | Intersect | Except
  deriving (Eq, Show)

data CompoundTail = CompoundTail [OrderTerm] (Maybe Expr) (Maybe Expr) -- ^ ORDER BY, LIMIT, OFFSET
  deriving (Eq, Show)

-- | One select (its own ORDER BY / LIMIT / OFFSET inside 'SelectStmt'), or @first op select op select ...@ (left-associative) with its tail (SPEC 5.1).
data QueryBody
  = Plain SelectStmt
  | Compound SelectStmt [(SetOp, SelectStmt)] CompoundTail
  deriving (Eq, Show)

-- | A full select: optional WITH, then the body.
data Query = Query
  { queryWith :: Maybe With
  , queryBody :: QueryBody
  } deriving (Eq, Show)

-- | @WITH [RECURSIVE] cte, ...@ (SPEC 5.2).
data With = With Bool [Cte]
  deriving (Eq, Show)

-- | @name [(columns)] AS (query)@.
data Cte = Cte Ident (Maybe [Ident]) Query
  deriving (Eq, Show)

-- | Where INSERT's rows come from (SPEC 1.6, 5.4).
data InsertSource
  = InsertValues [[Expr]]
  | InsertSelect Query

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
  | Insert Ident (Maybe [Ident]) InsertSource
  | Update Ident [(Ident, Expr)] (Maybe Expr) -- ^ table, assignments, WHERE
  | Delete Ident (Maybe Expr)
  | Select Query
  | CreateView Bool Ident (Maybe [Ident]) Query -- ^ IF NOT EXISTS, name, column names, select
  | DropView Bool Ident
  | CreateIndex Bool Bool Ident Ident [Ident] -- ^ UNIQUE, IF NOT EXISTS, index, table, columns
  | DropIndex Bool Ident
  | AlterAddColumn Ident ColumnDef
  | AlterRenameTable Ident Ident
  | AlterRenameColumn Ident Ident Ident -- ^ table, column, new name
  | Begin
  | Commit
  | Rollback

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
  ESubquery _ -> [] -- a subquery's aggregate calls are its own
  EExists _ -> []
  EInSelect _ x _ -> [x]
