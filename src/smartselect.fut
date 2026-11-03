import "shared"
import "partition"

-- Like quickselect_fused,
-- but uses a smarter pivot selection strategy that guarantees O(n) *.
-- https://tildesites.bowdoin.edu/~ltoma/teaching/cs231/2018spring/Lectures/selection.pdf

-- * This is technially not the correct implementation of the median-of-medians algorithm,
--   since it gives an approximation of the median using an iterative heuristic.
--   The actual O(n) implementation seems to *require* recursion.
--   Thus this is still O(n^2) but with a higher constant factor,
--   but it does not suffer from adversarial inputs.

-- Simple decision tree for the median of small groups of size <=5.
-- Uses lower median for even sized groups.
def median_of_3 't ((<): t -> t -> bool) (a: t) (b: t) (c: t) : t =
  let (lo, hi) = minmax (<) a b
  in max (<) lo (min (<) hi c)

def median_of_4 't ((<): t -> t -> bool) (a: t) (b: t) (c: t) (d: t) : t =
  let ab_lo = min (<) a b
  let cd_lo = min (<) c d
  in max (<) ab_lo cd_lo

def median_of_5 't ((<): t -> t -> bool) (a: t) (b: t) (c: t) (d: t) (e: t) : t =
  let (ab_lo, ab_hi) = minmax (<) a b
  let (cd_lo, cd_hi) = minmax (<) c d
  let lo = max (<) ab_lo cd_lo
  let hi = min (<) ab_hi cd_hi
  in median_of_3 (<) lo hi e

def median_of_lteq_5 [n] 't (ne: t) ((<): t -> t -> bool) (xs: [n]t) : t =
  match n
    case 0i64 -> ne
    case 1i64 -> xs[0]
    case 2i64 -> min (<) xs[0] xs[1]
    case 3i64 -> median_of_3 (<) xs[0] xs[1] xs[2]
    case 4i64 -> median_of_4 (<) xs[0] xs[1] xs[2] xs[3]
    case _    -> median_of_5 (<) xs[0] xs[1] xs[2] xs[3] xs[4]

-- Group segments into groups of size <=5, and returns the median of each group.
def median_reduce [m][n] 't (ne: t) ((<): t -> t -> bool) (shp: [m]i64) (flat: [n]t) : ([m]i64, []t) =
  let shp' = map (\s -> (s + 4i64) / 5i64) shp
  let n' = reduce (+) 0i64 shp'

  let (starts, _) = get_sgm_starts_and_ends shp
  let (starts', _) = get_sgm_starts_and_ends shp'

  let ids = get_sgm_ids starts n
  let g_ids = get_group_ids starts starts' ids

  let (g_starts, g_ends) = get_group_starts_and_ends g_ids n'
  let fn_median = \i ->
    median_of_lteq_5 ne (<) flat[g_starts[i] : g_ends[i]]

  let medians = map fn_median (iota n')
  in (shp', medians)

-- Repeatedly group, take medians, and reduce every segment
-- untill a single element remains in each segment.
def median_of_medians [m][n] 't (ne: t) ((<): t -> t -> bool) (shp: [m]i64) (flat: [n]t) : [m]t =
  let (shp', flat') =
    loop (shp', flat') = (shp, flat)
    while any (i64.>5i64) shp' do
      median_reduce ne (<) shp' flat'

  let (starts, ends) = get_sgm_starts_and_ends shp'
  let fn_median = \i ->
    if shp'[i] == 0i64 then ne
    else median_of_lteq_5 ne (<) flat'[starts[i] : ends[i]]

  in map fn_median (iota m)


def select_pivots [m][n] 't (ne: t) ((<): t -> t -> bool) (shp: [m]i64) (flat: [n]t) : [m]t =
  median_of_medians ne (<) shp flat

def smartselect [m][n] 't
  (ne: t)
  ((<): t -> t -> bool)
  ((<=): t -> t -> bool)
  ((>): t -> t -> bool)
  (ks: [m]i64)
  (shp: [m]i64)
  (flat: [n]t)
  : [m]t =
  let (starts, _) = get_sgm_starts_and_ends shp
  let ids = get_sgm_ids starts n
  let result = replicate m ne
  let (_, _, _, _, result) =
    loop (ks, shp, ids, flat, result) = (ks, shp, ids, flat, result)
    while any (i64.> 0i64) shp do
      let pivots = select_pivots ne (<) shp flat
      in partition_fused (<) (<=) (>) pivots ks shp ids flat result
  in result


def smartselect_i32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]i32) : [m]i32 =
  smartselect (-1i32) (i32.<) (i32.<=) (i32.>) ks shp flat

def smartselect_f32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  smartselect (-1f32) (f32.<) (f32.<=) (f32.>) ks shp flat


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  smartselect_f32 ks shp flat
