-- | Window calls in a SELECT (SPEC 6): resolving the window each call uses,
-- checking its frame, compiling its expressions, and adding the values of the
-- calls to the rows as extra columns that "Engine.Compile" reads like aggregate slots.
-- The computation itself is "Engine.Window".
module Engine.WindowPlan (planWindows) where

import Control.Applicative ((<|>))
import Control.Monad (unless, when)
import Data.List (nub, transpose)
import Data.Maybe (fromMaybe)
import Engine.Catalog (Row)
import Engine.Compile
import Engine.Error
import Engine.Syntax
import Engine.Value
import Engine.Window

-- | Plan the window calls of one SELECT. @scope@ is where the calls' expressions are written
-- (no window calls allowed in it); the calls get slots from index @firstSlot@ on. Returns the
-- slots for the scope of the result columns and ORDER BY, and the step that appends the values to the rows.
planWindows :: Scope -> [(Ident, WindowSpec)] -> Int -> [Expr] -> Result (WindowContext, Env -> [Row] -> Result [Row])
planWindows scope defs firstSlot calls = do
  checkDistinct [] (map fst defs)
  jobs <- mapM (planCall scope defs) uniqueCalls
  let slots = zip uniqueCalls [firstSlot ..]
      addColumns outer rows
        | null jobs = Right rows
        | otherwise = do
            columns <- mapM (\job -> runWindow outer job rows) jobs
            Right (zipWith (++) rows (transpose columns))
  Right (WindowSlots slots, addColumns)
  where
    uniqueCalls = nub calls
    checkDistinct _ [] = Right ()
    checkDistinct seen (n : rest)
      | identKey n `elem` seen = Left (duplicateWindow n)
      | otherwise = checkDistinct (identKey n : seen) rest

planCall :: Scope -> [(Ident, WindowSpec)] -> Expr -> Result WindowJob
planCall scope defs call = case call of
  EWindow name args over -> do
    function <- resolveWindowFunction name (length args)
    spec <- resolveRef defs [] over
    frame <- checkedFrame (wsOrder spec) (fromMaybe defaultFrame (wsFrame spec))
    argFns <- mapM (fmap snd . compileExpr scope) args
    partitionFns <- mapM (fmap snd . compileExpr specScope) (wsPartition spec)
    orderFns <- mapM (\(OrderTerm e _ _) -> snd <$> compileExpr specScope e) (wsOrder spec)
    Right (WindowJob function argFns partitionFns (wsOrder spec) orderFns frame)
  _ -> Left (noSuchFunction "window") -- planWindows is given window calls only
  where
    -- a result-column alias is not visible in a window-spec (SPEC 6.1)
    specScope = scope {scopeAliases = []}

-- | Without a frame clause: from the first row to the last peer of the current row.
defaultFrame :: Frame
defaultFrame = Frame Range UnboundedPreceding CurrentRow

-- | The spec a call uses: a named one, or a written one added to its base window (SPEC 6.1).
resolveRef :: [(Ident, WindowSpec)] -> [String] -> WindowRef -> Result WindowSpec
resolveRef defs seen over = case over of
  OverName n -> named n
  OverSpec spec -> case wsBase spec of
    Nothing -> Right spec
    Just b -> do
      base <- named b
      Right WindowSpec
        { wsBase = Nothing
        , wsPartition = if null (wsPartition spec) then wsPartition base else wsPartition spec
        , wsOrder = if null (wsOrder spec) then wsOrder base else wsOrder spec
        , wsFrame = wsFrame spec <|> wsFrame base
        }
  where
    named n = case lookup (identKey n) [(identKey d, s) | (d, s) <- defs] of
      Just spec | identKey n `notElem` seen -> resolveRef defs (identKey n : seen) (OverSpec spec)
      _ -> Left (noSuchWindow n)

-- | Reject the frames SPEC 6.2 rejects: negative or non-numeric offsets, a RANGE offset without exactly one ORDER BY term, and the unsupported shapes.
checkedFrame :: [OrderTerm] -> Frame -> Result Frame
checkedFrame order frame@(Frame unit start end) = do
  checkOffset True start
  checkOffset False end
  when (unit == Range && any hasOffset [start, end] && length order /= 1) (Left rangeNeedsOneOrder)
  unless supported (Left unsupportedFrame)
  Right frame
  where
    checkOffset isStart b = case b of
      Preceding k -> offsetOk isStart k
      Following k -> offsetOk isStart k
      _ -> Right ()
    offsetOk isStart k = case (unit, k) of
      (Rows, VInt i) | i >= 0 -> Right ()
      (Range, VInt i) | i >= 0 -> Right ()
      (Range, VReal d) | d >= 0 -> Right ()
      _ -> Left (frameOffset isStart (unit == Rows))
    hasOffset b = case b of Preceding _ -> True; Following _ -> True; _ -> False
    supported = case (start, end) of
      (UnboundedFollowing, _) -> False
      (_, UnboundedPreceding) -> False
      (CurrentRow, Preceding _) -> False
      (Following _, CurrentRow) -> False
      (Following _, Preceding _) -> False
      _ -> True
