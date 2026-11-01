import "shared"
import "partition"

-- Like quickselect_fused,
-- but uses a smarter pivot selection strategy that guarantees O(n) *.
-- https://tildesites.bowdoin.edu/~ltoma/teaching/cs231/2018spring/Lectures/selection.pdf

-- * This is technially not the correct implementation of the median-of-medians algorithm,
--   since it gives an approximation of the median using an iterative heuristic.
--   The actual O(n) implementation seems to *require* recursion.

-- Simple decision tree for the median of small gruops of size <=5.
-- Uses lower median For even sized groups.
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
def median_of_lteq_5 [n] 't ((<): t -> t -> bool) (flat: [n]t) : t =
  match n
    case 1i64 -> flat[0]
    case 2i64 -> min (<) flat[0] flat[1]
    case 3i64 -> median_of_3 (<) flat[0] flat[1] flat[2]
    case 4i64 -> median_of_4 (<) flat[0] flat[1] flat[2] flat[3]
    case _    -> median_of_5 (<) flat[0] flat[1] flat[2] flat[3] flat[4]

def medians_per_group [n] 't ((<): t -> t -> bool) (flat: [n]t) (s: i64) (e: i64) : (i64, []t) =
  let num_groups = (e - s + 4i64) / 5i64
  let fn_group = \g ->
    let start = s + g * 5i64
    let end = start + min (i64.<) 5i64 (e - start)
    in median_of_lteq_5 (<) flat[start : end]

  in (num_groups, map fn_group (iota num_groups))

-- Repeatedly computes the group of 5 median of medians until the result is a single value.
-- This is a heuristic approximation of the median,
def median_of_medians [n] 't ((<): t -> t -> bool) (flat: [n]t) (s: i64) (e: i64) : t =
  let (_, result) =
    loop (len, mom) = (medians_per_group (<) flat s e)
    while len > 5 do  medians_per_group (<) mom 0 len
  in median_of_lteq_5 (<) result

def smartselect [m][n] 't
  (ne: t)
  ((<): t -> t -> bool)
  ((<=): t -> t -> bool)
  ((>): t -> t -> bool)
  (ks: [m]i64)
  (shp: [m]i64)
  (flat: [n]t)
  : [m]t =
  let ids = get_sgm_ids shp flat
  let result = replicate m ne
  let (_, _, _, _, result) =
    loop (ks, shp, ids, flat, result) = (ks, shp, ids, flat, result)
    while any (i64.> 0i64) shp do
      let (starts, ends) = get_sgm_starts_and_ends shp
      let fn_pivot = \i ->
        if shp[i] == 0i64 then ne
        else median_of_medians (<) flat starts[i] ends[i]

      let pivots = map fn_pivot (iota m)
      in partition_fused (<) (<=) (>) pivots ks shp ids flat result
  in result


def smartselect_i32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]i32) : [m]i32 =
  smartselect (-1i32) (i32.<) (i32.<=) (i32.>) ks shp flat

def smartselect_f32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  smartselect (-1f32) (f32.<) (f32.<=) (f32.>) ks shp flat


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  smartselect_f32 ks shp flat
