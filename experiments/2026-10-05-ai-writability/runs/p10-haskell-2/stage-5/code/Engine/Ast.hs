-- | Syntax trees produced by the parser and consumed by the executor.
-- Names are kept as the statement wrote them (error messages spell them so).
module Engine.Ast
  ( Statement(..)
  , ColumnDef(..)
  , ColumnConstraint(..)
  , TableConstraint(..)
  , Select(..)
  , SimpleSelect(..)
  , SetOp(..)
  , With(..)
  , Cte(..)
  , InsertSource(..)
  , AlterAction(..)
  , SelectItem(..)
  , FromClause(..)
  , FromItem(..)
  , Join(..)
  , JoinKind(..)
  , JoinConstraint(..)
  , OrderTerm(..)
  , AggCall(..)
  , traverseExpr
  , subExpressions
  , NullsPos(..)
  , Expr(..)
  , UnOp(..)
  , BinOp(..)
  ) where

import Data.Functor.Const (Const(..))
import Engine.Value (ColType, Value)

data Statement
  = CreateTable
      { ctIfNotExists :: Bool, ctName :: String
      , ctColumns :: [ColumnDef], ctConstraints :: [TableConstraint] }
  | DropTable { dtIfExists :: Bool, dtName :: String }
  | CreateView { cvIfNotExists :: Bool, cvName :: String, cvColumns :: [String], cvSelect :: Select }
  | DropView { dvIfExists :: Bool, dvName :: String }
  | CreateIndex { ciUnique :: Bool, ciIfNotExists :: Bool, ciName :: String, ciTable :: String, ciColumns :: [String] }
  | DropIndex { diIfExists :: Bool, diName :: String }
  | AlterTable String AlterAction
  | Insert { insWith :: Maybe With, insTable :: String, insColumns :: Maybe [String], insSource :: InsertSource }
  | Update { updTable :: String, updSet :: [(String, Expr)], updWhere :: Maybe Expr }
  | Delete { delTable :: String, delWhere :: Maybe Expr }
  | SelectStmt Select
  | Begin
  | Commit
  | Rollback
  deriving (Show)

data InsertSource
  = FromValues [[Expr]]
  | FromQuery Select
  deriving (Show)

data AlterAction
  = AddColumn ColumnDef
  | RenameTable String
  | RenameColumn String String   -- old, new
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

-- | A full select: optional WITH, one or more simple selects joined by set operators (equal precedence,
-- left to right), then the ORDER BY / LIMIT / OFFSET that apply to the whole result (SPEC 5.1).
data Select = Select
  { selWith :: Maybe With
  , selFirst :: SimpleSelect
  , selRest :: [(SetOp, SimpleSelect)]
  , selOrderBy :: [OrderTerm]
  , selLimit :: Maybe Expr
  , selOffset :: Maybe Expr
  } deriving (Eq, Show)

-- | SELECT ... up to HAVING: no ORDER BY / LIMIT of its own.
data SimpleSelect = SimpleSelect
  { ssDistinct :: Bool
  , ssItems :: [SelectItem]
  , ssFrom :: Maybe FromClause
  , ssWhere :: Maybe Expr
  , ssGroupBy :: [Expr]
  , ssHaving :: Maybe Expr
  } deriving (Eq, Show)

data SetOp = Union | UnionAll | Intersect | Except
  deriving (Eq, Show)

-- | WITH [RECURSIVE] cte, ... (SPEC 5.2).
data With = With { withRecursive :: Bool, withCtes :: [Cte] }
  deriving (Eq, Show)

-- | A common table expression; an empty column list means "named as for a subquery source".
data Cte = Cte { cteName :: String, cteColumns :: [String], cteSelect :: Select }
  deriving (Eq, Show)

data SelectItem
  = Star
  | QualifiedStar String       -- q.*
  | Item Expr (Maybe String)   -- expression and optional alias
  deriving (Eq, Show)

-- | FROM: a first item and the joins applied to it from left to right (SPEC 4.1).
data FromClause = FromClause FromItem [Join]
  deriving (Eq, Show)

data FromItem
  = FromTable String (Maybe String)   -- table, alias
  | FromSelect Select (Maybe String)  -- ( select ), alias
  deriving (Eq, Show)

-- | ',', CROSS JOIN and a JOIN without a constraint are all 'JoinInner' with 'NoConstraint'.
data Join = Join JoinKind FromItem JoinConstraint
  deriving (Eq, Show)

data JoinKind = JoinInner | JoinLeft
  deriving (Eq, Show)

data JoinConstraint
  = NoConstraint
  | On Expr
  | Using [String]
  deriving (Eq, Show)

data NullsPos = NullsFirst | NullsLast
  deriving (Eq, Show)

data OrderTerm = OrderTerm
  { otExpr :: Expr
  , otDesc :: Bool
  , otNulls :: Maybe NullsPos
  } deriving (Eq, Show)

data Expr
  = ELit Value
  | EName String
  | EQualified String String   -- q.c
  | EColumnAt Int              -- the i-th column of the row; only produced by '*' expansion (Engine.Query)
  | ECall String [Expr]
  | EUnary UnOp Expr
  | EBinary BinOp Expr Expr
  | ECase (Maybe Expr) [(Expr, Expr)] (Maybe Expr)   -- operand, (WHEN, THEN) pairs, ELSE
  | EBetween Bool Expr Expr Expr                      -- negated?, x, low, high
  | EIn Bool Expr [Expr]                              -- negated?, x, list
  | ELike Bool Expr Expr                              -- negated?, x, pattern
  | ECast Expr ColType
  | EAggCall AggCall   -- a call written with '*', DISTINCT or ORDER BY (a plain call is an ECall)
  | ESubquery Select            -- ( select ) as a value
  | EExists Select
  | EInSelect Bool Expr Select  -- negated?, x, subquery
  | EAggRef Int        -- the k-th aggregate of the group; only produced by Engine.Aggregate
  deriving (Eq, Show)

-- | An aggregate call in its uniform form. count(*) has acStar and no arguments.
data AggCall = AggCall
  { acName :: String          -- as written
  , acStar :: Bool
  , acDistinct :: Bool
  , acArgs :: [Expr]
  , acOrder :: [OrderTerm]    -- ORDER BY inside the call
  } deriving (Eq, Show)

-- | Apply an action to each direct sub-expression (including those inside an AggCall).
traverseExpr :: Applicative f => (Expr -> f Expr) -> Expr -> f Expr
traverseExpr f expr = case expr of
  ECall n args -> ECall n <$> traverse f args
  EUnary op e -> EUnary op <$> f e
  EBinary op a b -> EBinary op <$> f a <*> f b
  ECase o bs els -> ECase <$> traverse f o <*> traverse (\(w, t) -> (,) <$> f w <*> f t) bs <*> traverse f els
  EBetween n x lo hi -> EBetween n <$> f x <*> f lo <*> f hi
  EIn n x items -> EIn n <$> f x <*> traverse f items
  ELike n x p -> ELike n <$> f x <*> f p
  ECast e t -> (`ECast` t) <$> f e
  EAggCall c -> (\as os -> EAggCall c { acArgs = as, acOrder = os })
                  <$> traverse f (acArgs c) <*> traverse (\o -> (\e -> o { otExpr = e }) <$> f (otExpr o)) (acOrder c)
  EInSelect n x sel -> (\x' -> EInSelect n x' sel) <$> f x
  ELit _ -> pure expr
  EName _ -> pure expr
  EQualified _ _ -> pure expr
  EColumnAt _ -> pure expr
  ESubquery _ -> pure expr   -- a subquery's own aggregates and names are its own
  EExists _ -> pure expr
  EAggRef _ -> pure expr

subExpressions :: Expr -> [Expr]
subExpressions = getConst . traverseExpr (\e -> Const [e])


data UnOp = Neg | Plus | Not
  deriving (Eq, Show)

data BinOp
  = Add | Sub | Mul | Div | Mod
  | Concat
  | Eq | Ne | Lt | Le | Gt | Ge
  | Is | IsNot
  | And | Or
  deriving (Eq, Show)
