-- | The abstract syntax produced by the parser and consumed by the executor.
module Engine.Syntax
  ( Ident
  , identKey
  , isRowidName
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
  , WindowSpec (..)
  , WindowRef (..)
  , Frame (..)
  , FrameUnit (..)
  , FrameBound (..)
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

-- | @rowid@, @_rowid_@ and @oid@: the names of a row's rowid (SPEC 7.1).
isRowidName :: Ident -> Bool
isRowidName n = identKey n `elem` ["rowid", "_rowid_", "oid"]

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
  | EWindow Ident [Expr] WindowRef -- ^ @name(args) OVER ...@; @count(*)@ has no args
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

-- | @(base-name PARTITION BY ... ORDER BY ... frame)@ (SPEC 6.1).
data WindowSpec = WindowSpec
  { wsBase :: Maybe Ident
  , wsPartition :: [Expr]
  , wsOrder :: [OrderTerm]
  , wsFrame :: Maybe Frame
  } deriving (Eq, Show)

-- | What follows OVER: a window name, or a parenthesised spec.
data WindowRef = OverName Ident | OverSpec WindowSpec
  deriving (Eq, Show)

data FrameUnit = Rows | Range
  deriving (Eq, Show)

-- | Unit, start, end (a lone start has CURRENT ROW as its end).
data Frame = Frame FrameUnit FrameBound FrameBound
  deriving (Eq, Show)

-- | The offsets are the literal's value, negative ones kept for the error of SPEC 6.2.
data FrameBound
  = UnboundedPreceding
  | Preceding Value
  | CurrentRow
  | Following Value
  | UnboundedFollowing
  deriving (Eq, Show)

data SelectStmt = SelectStmt
  { selDistinct :: Bool
  , selColumns :: [ResultCol]
  , selFrom :: Maybe FromClause
  , selWhere :: Maybe Expr
  , selGroupBy :: [Expr]
  , selHaving :: Maybe Expr
  , selWindows :: [(Ident, WindowSpec)] -- ^ the WINDOW clause
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
  EWindow _ args over -> args ++ case over of
    OverName _ -> []
    OverSpec (WindowSpec _ part order _) -> part ++ [x | OrderTerm x _ _ <- order]
  ECase operand branches other ->
    maybe [] pure operand ++ concat [[c, r] | (c, r) <- branches] ++ maybe [] pure other
  EBetween _ x lo hi -> [x, lo, hi]
  EIn _ x es -> x : es
  ELike _ x p -> [x, p]
  ECast x _ -> [x]
  ESubquery _ -> [] -- a subquery's aggregate calls are its own
  EExists _ -> []
  EInSelect _ x _ -> [x]
