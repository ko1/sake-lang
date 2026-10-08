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
  { selDistinct :: Bool
  , selItems :: [SelectItem]
  , selFrom :: Maybe String
  , selWhere :: Maybe Expr
  , selGroupBy :: [Expr]
  , selHaving :: Maybe Expr
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
  } deriving (Eq, Show)

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
  | EAggCall AggCall   -- a call written with '*', DISTINCT or ORDER BY (a plain call is an ECall)
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
  ELit _ -> pure expr
  EName _ -> pure expr
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
