-- | Window functions (SPEC 6): partitioning, ordering, frames and the value
-- each function gives a row. Works on rows and already compiled expressions;
-- naming, scopes and where a window call may appear are "Engine.WindowPlan".
module Engine.Window
  ( isWindowOnlyName
  , windowCalls
  , WindowFunction
  , resolveWindowFunction
  , WindowJob (..)
  , runWindow
  ) where

import Data.Array (Array, array, elems, listArray, (!))
import Data.List (groupBy, sortBy)
import Data.Maybe (fromMaybe)
import Engine.Aggregate (AggImpl (..), asAggregate, resolveAggregate)
import Engine.Catalog (Row)
import Engine.Error
import Engine.Operators (binaryOp)
import Engine.Scope (Env, RowFn)
import Engine.Sorting (compareKeys, groupOn)
import Engine.Syntax
import Engine.Value

data WindowFunction
  = RowNumber | Rank | DenseRank | PercentRank | CumeDist | Ntile
  | Lag | Lead | FirstValue | LastValue | NthValue
  | OverAggregate AggImpl -- ^ an aggregate (SPEC 3.2) computed over the frame

-- | Name, accepted argument counts (inclusive), function: the functions that exist only with OVER.
windowOnly :: [(String, (Int, Int, WindowFunction))]
windowOnly =
  [ ("row_number", (0, 0, RowNumber)), ("rank", (0, 0, Rank)), ("dense_rank", (0, 0, DenseRank))
  , ("percent_rank", (0, 0, PercentRank)), ("cume_dist", (0, 0, CumeDist)), ("ntile", (1, 1, Ntile))
  , ("lag", (1, 3, Lag)), ("lead", (1, 3, Lead)), ("first_value", (1, 1, FirstValue))
  , ("last_value", (1, 1, LastValue)), ("nth_value", (2, 2, NthValue)) ]

isWindowOnlyName :: Ident -> Bool
isWindowOnlyName n = identKey n `elem` map fst windowOnly

-- | The outermost window calls of an expression, in order, as the expressions themselves.
windowCalls :: Expr -> [Expr]
windowCalls e@(EWindow {}) = [e]
windowCalls e = concatMap windowCalls (childExprs e)

-- | Check the name and argument count of a function written with OVER.
-- @coll@ is the collation of the first argument, for min and max.
resolveWindowFunction :: Ident -> Int -> Collation -> Result WindowFunction
resolveWindowFunction name argc coll = case lookup (identKey name) windowOnly of
  Just (lo, hi, f)
    | argc >= lo && argc <= hi -> Right f
    | otherwise -> Left (wrongArgCount name)
  Nothing -> case asAggregate (ECall name (replicate argc (ELit VNull))) of
    Just call -> OverAggregate <$> resolveAggregate coll call
    Nothing -> Left (notWindowFunction name)

-- | One window call, compiled. 'wjFrame' is the frame with its default applied.
data WindowJob = WindowJob
  { wjFunction :: WindowFunction
  , wjArgs :: [RowFn]
  , wjPartition :: [RowFn]
  , wjPartitionColls :: [Collation]
  , wjOrder :: [OrderTerm]
  , wjOrderFns :: [RowFn]
  , wjOrderColls :: [Collation]
  , wjFrame :: Frame
  }

-- | The call's value for each row, in the order of the rows given.
runWindow :: Env -> WindowJob -> [Row] -> Result [Value]
runWindow outer job rows = do
  parts <- mapM (partitionValues outer job) (groupOn (wjPartitionColls job) (\(_, r) -> map ($ (r : outer)) (wjPartition job)) (zip [0 :: Int ..] rows))
  Right (elems (array (0, length rows - 1) (concat parts)))

-- | A row's position within its sorted partition, and the sorted partition.
data Partition = Partition
  { pSize :: Int
  , pRows :: Array Int Row
  , pKeys :: Array Int [Value] -- ^ ORDER BY values
  , pPeers :: Array Int (Int, Int, Int) -- ^ first and last position of the peers, number of the peer group
  }

partitionValues :: Env -> WindowJob -> [(Int, Row)] -> Result [(Int, Value)]
partitionValues outer job members = do
  values <- mapM (valueAt outer job part) [0 .. n - 1]
  Right (zip [i | (_, i, _) <- keyed] values)
  where
    terms = wjOrder job
    colls = wjOrderColls job
    keyed = sortBy (\(a, _, _) (b, _, _) -> compareKeys terms colls a b)
      [(map ($ (r : outer)) (wjOrderFns job), i, r) | (i, r) <- members]
    n = length keyed
    groups = groupBy (\(a, _, _) (b, _, _) -> compareKeys terms colls a b == EQ) keyed
    lens = map length groups
    part = Partition
      { pSize = n
      , pRows = listArray (0, n - 1) [r | (_, _, r) <- keyed]
      , pKeys = listArray (0, n - 1) [k | (k, _, _) <- keyed]
      , pPeers = listArray (0, n - 1)
          (concat [replicate len (s, s + len - 1, g) | (g, s, len) <- zip3 [0 ..] (scanl (+) 0 lens) lens])
      }

valueAt :: Env -> WindowJob -> Partition -> Int -> Result Value
valueAt outer job part i = case wjFunction job of
  RowNumber -> Right (VInt (fromIntegral i + 1))
  Rank -> Right (VInt (fromIntegral first + 1))
  DenseRank -> Right (VInt (fromIntegral group + 1))
  PercentRank -> Right (VReal (if n == 1 then 0 else fromIntegral first / fromIntegral (n - 1)))
  CumeDist -> Right (VReal (fromIntegral (lastPeer + 1) / fromIntegral n))
  Ntile -> case asInteger (arg 0) of
    Just k | k > 0 -> Right (VInt (fromIntegral (bucket (fromInteger (min k (fromIntegral n))))))
    _ -> Left ntileArgument
  Lag -> shifted (-1)
  Lead -> shifted 1
  FirstValue -> Right (if lo <= hi then argOn lo 0 else VNull)
  LastValue -> Right (if lo <= hi then argOn hi 0 else VNull)
  NthValue -> case positiveInteger (arg 1) of
    Nothing -> Left nthValueArgument
    Just k | lo + k - 1 <= hi -> Right (argOn (lo + k - 1) 0)
           | otherwise -> Right VNull
  OverAggregate impl -> aggFold impl [[f (row j : outer) | f <- wjArgs job] | j <- [lo .. hi]]
  where
    n = pSize part
    row j = pRows part ! j
    (first, lastPeer, group) = pPeers part ! i
    env = row i : outer
    arg k = (wjArgs job !! k) env
    argOn j k = (wjArgs job !! k) (row j : outer)
    (lo, hi) = frameBounds (wjOrder job) (wjFrame job) part i
    -- ntile: the first (n mod k) buckets hold one more row
    bucket k =
      let (size, extra) = n `divMod` k
          cut = extra * (size + 1)
       in if i < cut then i `div` (size + 1) + 1 else extra + (i - cut) `div` size + 1
    shifted :: Integer -> Result Value
    shifted sign
      | hasOffset && arg 1 == VNull = Right VNull
      | target >= 0 && target < toInteger n = Right (argOn (fromInteger target) 0)
      | length (wjArgs job) > 2 = Right (arg 2)
      | otherwise = Right VNull
      where
        hasOffset = length (wjArgs job) > 1
        target = toInteger i + sign * (if hasOffset then fromMaybe 0 (asInteger (arg 1)) else 1)

-- | An integer for a value, truncating a REAL and reading a TEXT by its numeric prefix; NULL has none.
asInteger :: Value -> Maybe Integer
asInteger v = case v of
  VInt k -> Just (toInteger k)
  VReal d -> Just (truncate d)
  VText s -> asInteger (numericPrefix s)
  VNull -> Nothing

-- | A positive whole number (an INTEGER, or a REAL with no fraction).
positiveInteger :: Value -> Maybe Int
positiveInteger v = case v of
  VInt k | k > 0 -> Just (fromIntegral (min k 1000000000))
  VReal d | d > 0, d == fromInteger (truncate d) -> Just (fromInteger (min 1000000000 (truncate d)))
  _ -> Nothing

-- | The first and last position of row @i@'s frame, clipped to the partition; empty when first > last (SPEC 6.2).
frameBounds :: [OrderTerm] -> Frame -> Partition -> Int -> (Int, Int)
frameBounds terms (Frame unit startBound endBound) part i = (max 0 (position True startBound), min (n - 1) (position False endBound))
  where
    n = pSize part
    (firstPeer, lastPeer, _) = pPeers part ! i
    position isStart b = case (unit, b) of
      (_, UnboundedPreceding) -> if isStart then 0 else -1
      (_, UnboundedFollowing) -> if isStart then n else n - 1
      (Rows, CurrentRow) -> i
      (Rows, Preceding k) -> i - count k
      (Rows, Following k) -> i + count k
      (Range, CurrentRow) -> if isStart then firstPeer else lastPeer
      (Range, Preceding k) -> byValue isStart True k
      (Range, Following k) -> byValue isStart False k
    count (VInt k) = fromIntegral (min k (fromIntegral n + 1))
    count _ = 0
    -- RANGE n PRECEDING / FOLLOWING: compare the ORDER BY value with the current one moved by n.
    byValue isStart before k
      | current == VNull = if isStart then firstPeer else lastPeer
      | isStart = firstWhere (/= LT)
      | otherwise = lastWhere (/= GT)
      where
        descending = case terms of OrderTerm _ d _ : _ -> d; [] -> False
        keyAt j = case pKeys part ! j of k : _ -> k; [] -> VNull
        current = keyAt i
        towardsSmaller = before /= descending
        target = binaryOp (if towardsSmaller then Sub else Add) Nothing Nothing Binary current k
        direct a b = (if descending then flip compareValues else compareValues) a b
        positions = [j | j <- [0 .. n - 1], keyAt j /= VNull]
        firstWhere ok = case [j | j <- positions, ok (direct (keyAt j) target)] of j : _ -> j; [] -> n
        lastWhere ok = case [j | j <- positions, ok (direct (keyAt j) target)] of [] -> -1; js -> last js
