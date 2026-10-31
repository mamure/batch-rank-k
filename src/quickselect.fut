import "shared"
import "partition"

-- Flattened batch rank-search-k.
-- Based on the handout pseudo code, but transformed to allow irregular arrays via flattening.
-- It uses quickselect with the pivot chosen as the last element in each segment
-- This is for simplicity as it avoids dealing with random number generation,
-- however an adversarial input is trivial to construct.

def quickselect [m][n] 't
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
  let active = map (i64.> 0i64) shp
  let (_, _, _, _, _, result) =
    loop (ks, shp, active, ids, flat, result) = (ks, shp, active, ids, flat, result)
    while (any (== true) active) do
      let (_, ends) = get_sgm_starts_and_ends shp
      let fn_pivot = \i ->
        if shp[i] == 0i64 then ne
        else flat[ends[i] - 1i64]

      let pivots = map fn_pivot (iota m)
      in partition (<) (<=) (>) pivots ks shp active ids flat result
  in result


def quickselect_i32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]i32) : [m]i32 =
  quickselect (-1i32) (i32.<) (i32.<=) (i32.>) ks shp flat

def quickselect_f32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  quickselect (-1f32) (f32.<) (f32.<=) (f32.>) ks shp flat


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  quickselect_f32 ks shp flat
