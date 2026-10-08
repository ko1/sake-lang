-- | Computing window functions (SPEC 6.2, 6.3) over the rows a query would otherwise produce.
-- Planning (names, frames, validity) is in Engine.Window; this module only runs a finished plan.
module Engine.WindowEval
  ( WindowPlan(..)
  , WindowFunction(..)
  , appendWindowColumns
  ) where

import Data.Array (Array, listArray, (!))
import Data.List (groupBy, sortBy, transpose)
import qualified Data.IntMap.Strict as IntMap
import qualified Data.Map.Strict as Map
import Engine.Aggregate (AggSpec, computeAggregate)
import Engine.Ast (Frame(..), FrameBound(..), FrameUnit(..), OrderTerm(..))
import Engine.Coerce (toNumber)
import Engine.Expr (evalExpr)
import Engine.Scope (Bound, Env, exprCollation)
import Engine.Sorting
import Engine.Value

-- | One window call, bound: what it computes, and how its rows are partitioned, ordered and framed.
data WindowPlan = WindowPlan
  { wpFunction :: WindowFunction
  , wpPartition :: [Bound]
  , wpOrder :: [(OrderTerm, Bound)]
  , wpFrame :: Frame             -- already validated and with the default filled in
  }

data WindowFunction
  = WinAggregate AggSpec         -- an aggregate over the frame
  | WinRowNumber | WinRank | WinDenseRank | WinPercentRank | WinCumeDist
  | WinNtile Bound
  | WinLag Bool Bound (Maybe Bound) (Maybe Bound)   -- earlier rows (lag) or later (lead)?, x, offset, default
  | WinFirstValue Bound
  | WinLastValue Bound
  | WinNthValue Bound Bound

-- | Append one column per window call to every row. Rows keep their order; the values of call k
-- are at position (row width + k).
appendWindowColumns :: Env -> [WindowPlan] -> [[Value]] -> Either String [[Value]]
appendWindowColumns _ [] rows = Right rows
appendWindowColumns ctx plans rows = do
  columns <- traverse (\plan -> windowColumn ctx plan rows) plans
  Right (zipWith (++) rows (transpose columns))

-- | The value of one window call for each row, in the rows' order.
windowColumn :: Env -> WindowPlan -> [[Value]] -> Either String [Value]
windowColumn ctx plan rows = do
  perPartition <- traverse (partitionValues ctx plan) partitions
  Right (IntMap.elems (IntMap.fromList (concat perPartition)))
  where
    key r = [ valueKey (exprCollation b) (evalExpr (r : ctx) b) | b <- wpPartition plan ]
    partitions = map reverse (Map.elems (Map.fromListWith (++) [ (key r, [(i, r)]) | (i, r) <- zip [0 ..] rows ]))

-- | A partition sorted by the window's ORDER BY, with what the functions ask of it.
data Part = Part
  { pSize :: Int
  , pRows :: Array Int [Value]
  , pKeys :: Array Int [Value]   -- ORDER BY values of each row
  , pPeerStart :: Array Int Int  -- first / last position of the row's peers
  , pPeerEnd :: Array Int Int
  , pGroup :: Array Int Int      -- index of the row's peer group
  }

-- | (original index, value) for each row of one partition.
partitionValues :: Env -> WindowPlan -> [(Int, [Value])] -> Either String [(Int, Value)]
partitionValues ctx plan members = do
  values <- traverse (valueAt ctx plan part) [0 .. m - 1]
  Right (zip (map (fst . snd) sorted) values)
  where
    terms = [ (t, exprCollation b) | (t, b) <- wpOrder plan ]
    keyed = [ (map (\(_, b) -> evalExpr (r : ctx) b) (wpOrder plan), member) | member@(_, r) <- members ]
    sorted = sortBy (\a b -> compareByTerms terms (fst a) (fst b)) keyed
    m = length sorted
    groups = groupBy (\a b -> compareByTerms terms (fst a) (fst b) == EQ) (zip (map fst sorted) [0 :: Int ..])
    perRow f = listArray (0, m - 1) (concat [ f gi (map snd g) | (gi, g) <- zip [0 :: Int ..] groups ])
    part = Part
      { pSize = m
      , pRows = listArray (0, m - 1) (map (snd . snd) sorted)
      , pKeys = listArray (0, m - 1) (map fst sorted)
      , pPeerStart = perRow (\_ g -> map (const (minimum g)) g)
      , pPeerEnd = perRow (\_ g -> map (const (maximum g)) g)
      , pGroup = perRow (\gi g -> map (const gi) g)
      }

-- | The value of the call for the row at position p of the sorted partition.
valueAt :: Env -> WindowPlan -> Part -> Int -> Either String Value
valueAt ctx plan part p = case wpFunction plan of
  WinAggregate spec -> computeAggregate ctx spec [ pRows part ! j | j <- [lo .. hi] ]
  WinRowNumber -> Right (VInt (p + 1))
  WinRank -> Right (VInt (pPeerStart part ! p + 1))
  WinDenseRank -> Right (VInt (pGroup part ! p + 1))
  WinPercentRank
    | m <= 1 -> Right (VReal 0)
    | otherwise -> Right (VReal (fromIntegral (pPeerStart part ! p) / fromIntegral (m - 1)))
  WinCumeDist -> Right (VReal (fromIntegral (pPeerEnd part ! p + 1) / fromIntegral m))
  WinNtile b -> case onRow b of
    VInt n | n > 0 -> Right (VInt (bucket n))
    _ -> Left "argument of ntile must be a positive integer"
  WinLag earlier x offset dflt -> case maybe (VInt 1) onRow offset of
    VNull -> Right VNull
    k -> let step = intOf k
             target = if earlier then p - step else p + step
         in Right $ if target >= 0 && target < m
              then evalExpr (pRows part ! target : ctx) x
              else maybe VNull onRow dflt
  WinFirstValue x -> Right (if empty then VNull else onPosition lo x)
  WinLastValue x -> Right (if empty then VNull else onPosition hi x)
  WinNthValue x n -> case onRow n of
    VInt k | k > 0 -> Right (if lo + k - 1 <= hi then onPosition (lo + k - 1) x else VNull)
    _ -> Left "second argument to nth_value must be a positive integer"
  where
    m = pSize part
    (lo, hi) = frameOf plan part p
    empty = lo > hi
    onRow b = evalExpr (pRows part ! p : ctx) b
    onPosition j b = evalExpr (pRows part ! j : ctx) b
    -- n buckets over m rows, the first (m mod n) of them one row larger
    bucket n =
      let (base, extra) = m `divMod` n
          big = extra * (base + 1)
      in if p < big then p `div` (base + 1) + 1 else extra + (p - big) `div` base + 1

intOf :: Value -> Int
intOf v = case toNumber v of
  VInt n -> n
  VReal d -> truncate d
  _ -> 0

-- | The frame of the row at position p as an inclusive range of positions; empty is (0, -1).
frameOf :: WindowPlan -> Part -> Int -> (Int, Int)
frameOf plan part p
  | lo > hi = (0, -1)
  | otherwise = (lo, hi)
  where
    Frame unit start end = wpFrame plan
    m = pSize part
    lo = max 0 $ case start of
      UnboundedPreceding -> 0
      UnboundedFollowing -> m
      CurrentRow -> currentFirst
      OffsetPreceding n -> offsetStart unit (negate (rowsOffset n)) (negate (number n))
      OffsetFollowing n -> offsetStart unit (rowsOffset n) (number n)
    hi = min (m - 1) $ case end of
      UnboundedPreceding -> -1
      UnboundedFollowing -> m - 1
      CurrentRow -> currentLast
      OffsetPreceding n -> offsetEnd unit (negate (rowsOffset n)) (negate (number n))
      OffsetFollowing n -> offsetEnd unit (rowsOffset n) (number n)
    (currentFirst, currentLast) = case unit of
      FrameRows -> (p, p)
      FrameRange -> (pPeerStart part ! p, pPeerEnd part ! p)
    rowsOffset = intOf
    offsetStart FrameRows d _ = p + d
    offsetStart FrameRange _ t = rangeStart t
    offsetEnd FrameRows d _ = p + d
    offsetEnd FrameRange _ t = rangeEnd t
    -- RANGE offsets: signed distance t of a row's ORDER BY value from the current row's, in the order's direction
    desc = case wpOrder plan of
      (term, _) : _ -> otDesc term
      [] -> False
    keyAt j = case pKeys part ! j of
      k : _ -> k
      [] -> VNull
    current = keyAt p
    distance j = if desc then number current - number (keyAt j) else number (keyAt j) - number current
    candidates = [ j | j <- [0 .. m - 1], not (isNull (keyAt j)) ]
    -- a NULL current value is within range of its NULL peers only
    rangeStart t
      | isNull current = pPeerStart part ! p
      | otherwise = case [ j | j <- candidates, distance j >= t ] of
          j : _ -> j
          [] -> m
    rangeEnd t
      | isNull current = pPeerEnd part ! p
      | otherwise = case [ j | j <- candidates, distance j <= t ] of
          [] -> -1
          js -> last js

number :: Value -> Rational
number v = case toNumber v of
  VInt n -> fromIntegral n
  VReal d -> toRational d
  _ -> 0
