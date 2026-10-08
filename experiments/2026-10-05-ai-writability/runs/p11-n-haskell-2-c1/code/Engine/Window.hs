-- | Window functions, planning side (SPEC 6.1, 6.2): finding the calls in a query, resolving named
-- windows, validating frames, and binding. Running a plan is in Engine.WindowEval.
module Engine.Window
  ( WindowPlan
  , containsWindow
  , resolveWindows
  , liftWindows
  , bindWindow
  , appendWindowColumns
  ) where

import Control.Applicative ((<|>))
import Control.Monad (when)
import Control.Monad.State.Strict (StateT, get, put)
import Data.List (findIndex)
import Data.Maybe (listToMaybe)
import Engine.Aggregate (bindAggregate, checkCall)
import Engine.Ast
import Engine.Expr (bindExpr)
import Engine.Functions
import Engine.Names (foldName)
import Engine.Scope (Bound, Scope)
import Engine.Value (Value(..))
import Engine.WindowEval

-- Finding and resolving ---------------------------------------------------------------

-- | The name (as written) of the first window call in the expression.
containsWindow :: Expr -> Maybe String
containsWindow (EWindow c) = Just (wcName c)
containsWindow e = listToMaybe [ n | Just n <- map containsWindow (subExpressions e) ]

-- | Replace every window reference of the expression (OVER w, or a spec with a base) by a full spec,
-- using the WINDOW clause of its simple select. Windows nested in a window call are left alone: binding rejects them.
resolveWindows :: [(String, WindowSpec)] -> Expr -> Either String Expr
resolveWindows named = go
  where
    go (EWindow c) = (\spec -> EWindow c { wcOver = OverSpec spec }) <$> resolveSpec named (refSpec (wcOver c))
    go e = traverseExpr go e
    refSpec (OverName n) = WindowSpec (Just n) [] [] Nothing
    refSpec (OverSpec s) = s

-- | A spec without a base: the base's parts, with the ones the spec writes added (SPEC 6.1).
resolveSpec :: [(String, WindowSpec)] -> WindowSpec -> Either String WindowSpec
resolveSpec named = go (length named)
  where
    go depth spec = case wsBase spec of
      Nothing -> Right spec
      Just n -> case lookup (foldName n) [ (foldName k, s) | (k, s) <- named ] of
        Nothing -> Left ("no such window: " ++ n)
        Just _ | depth < 0 -> Left ("circular window definition: " ++ n)
        Just base -> merge spec <$> go (depth - 1 :: Int) base
    merge spec base = WindowSpec
      { wsBase = Nothing
      , wsPartition = if null (wsPartition spec) then wsPartition base else wsPartition spec
      , wsOrder = if null (wsOrder spec) then wsOrder base else wsOrder spec
      , wsFrame = wsFrame spec <|> wsFrame base }

-- | Replace each outermost window call by a slot reference; slots start at @base@ (after the aggregates).
-- Identical calls share a slot.
liftWindows :: Int -> Expr -> StateT [WindowCall] (Either String) Expr
liftWindows base e = case e of
  EWindow c -> EAggRef . (base +) <$> slotFor c
  _ -> traverseExpr (liftWindows base) e
  where
    slotFor c = do
      calls <- get
      case findIndex (== c) calls of
        Just k -> pure k
        Nothing -> put (calls ++ [c]) >> pure (length calls)

-- Binding ---------------------------------------------------------------------------------

-- | Bind a lifted call: its function, partition and order expressions, and its frame.
bindWindow :: Scope -> WindowCall -> Either String WindowPlan
bindWindow scope c = do
  spec <- case wcOver c of
    OverSpec s | Nothing <- wsBase s -> Right s
    _ -> Left "internal error: unresolved window"
  function <- bindFunction scope c
  frame <- checkFrame (length (wsOrder spec)) (wsFrame spec)
  partition <- traverse (bindExpr scope) (wsPartition spec)
  order <- traverse (\t -> (,) t <$> bindExpr scope (otExpr t)) (wsOrder spec)
  Right (WindowPlan function partition order frame)

bindFunction :: Scope -> WindowCall -> Either String WindowFunction
bindFunction scope c = case windowSignature name of
  Just (kind, arity) -> do
    when (wcStar c || not (arityAccepts arity (length args))) wrongCount
    bound <- traverse (bindExpr scope) args
    Right (windowFunction kind bound)
  Nothing -> case aggregateSignature name of
    Just _ | isAggregateCall name (length args) -> do
      let call = AggCall (wcName c) (wcStar c) False args []
      checkCall call
      WinAggregate <$> bindAggregate scope call
    _ | Just _ <- lookupFunction name -> Left (wcName c ++ "() may not be used as a window function")
      | otherwise -> Left ("no such function: " ++ wcName c)
  where
    name = foldName (wcName c)
    args = wcArgs c
    wrongCount = Left ("wrong number of arguments to function " ++ wcName c ++ "()")

windowFunction :: WindowKind -> [Bound] -> WindowFunction
windowFunction kind args = case (kind, args) of
  (WkRowNumber, _) -> WinRowNumber
  (WkRank, _) -> WinRank
  (WkDenseRank, _) -> WinDenseRank
  (WkPercentRank, _) -> WinPercentRank
  (WkCumeDist, _) -> WinCumeDist
  (WkNtile, n : _) -> WinNtile n
  (WkLag, x : rest) -> WinLag True x (at 0 rest) (at 1 rest)
  (WkLead, x : rest) -> WinLag False x (at 0 rest) (at 1 rest)
  (WkFirstValue, x : _) -> WinFirstValue x
  (WkLastValue, x : _) -> WinLastValue x
  (WkNthValue, x : n : _) -> WinNthValue x n
  _ -> error "windowFunction: argument count was checked"
  where at i xs = listToMaybe (drop i xs)

-- | The frame to use (the default when none is written), or the error for a frame SQLite rejects (SPEC 6.2).
checkFrame :: Int -> Maybe Frame -> Either String Frame
checkFrame _ Nothing = Right (Frame FrameRange UnboundedPreceding CurrentRow)
checkFrame orderTerms (Just frame@(Frame unit start end)) = do
  when unsupported $ Left "unsupported frame specification"
  checkOffset "starting" start
  checkOffset "ending" end
  when (unit == FrameRange && any hasOffset [start, end] && orderTerms /= 1) $
    Left "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
  Right frame
  where
    unsupported = case (start, end) of
      (CurrentRow, OffsetPreceding _) -> True
      (OffsetFollowing _, CurrentRow) -> True
      (OffsetFollowing _, OffsetPreceding _) -> True
      _ -> False
    hasOffset (OffsetPreceding _) = True
    hasOffset (OffsetFollowing _) = True
    hasOffset _ = False
    checkOffset which b = case offsetOf b of
      Just v | not (valid v) -> Left ("frame " ++ which ++ " offset must be a non-negative " ++ kind)
      _ -> Right ()
    kind = if unit == FrameRows then "integer" else "number"
    valid v = case (unit, v) of
      (_, VInt n) -> n >= 0
      (FrameRange, VReal d) -> d >= 0
      _ -> False
    offsetOf (OffsetPreceding v) = Just v
    offsetOf (OffsetFollowing v) = Just v
    offsetOf _ = Nothing
