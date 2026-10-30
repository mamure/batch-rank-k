import "shared"

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
      -- select pivots
      let pivots = choose_pivots_last ne shp flat

      -- classify elements relative to pivots
      let fn_lt_flags = \i v -> if active[i] && v < pivots[i] then 1i64 else 0i64
      let fn_lteq_flags = \i v -> if active[i] && v <= pivots[i] then 1i64 else 0i64

      let lt_flags = map2 fn_lt_flags ids flat
      let lteq_flags = map2 fn_lteq_flags ids flat
      let lt = hist (+) 0i64 m ids lt_flags
      let lteq = hist (+) 0i64 m ids lteq_flags
      let gt = map2 (-) shp lteq

      -- update state based on classification
      -- kind: -1 inactive, 0 go left, 1 solved, 2 go right
      let fn_kinds = \i ->
        if !active[i] then -1i64
        else if ks[i] i64.<= lt[i] then 0i64
        else if ks[i] i64.<= lteq[i] then 1i64
        else 2i64
      let fn_shp = \i ->
        match fn_kinds i
          case 0i64 -> lt[i]
          case 2i64 -> gt[i]
          case _    -> 0i64
      let fn_ks = \i ->
        match fn_kinds i
          case 0i64 -> ks[i]
          case 2i64 -> ks[i] - lteq[i]
          case _    -> -1i64

      let idxs = iota m
      let kinds = map fn_kinds idxs
      let shp' = map fn_shp idxs
      let ks' = map fn_ks idxs

      let fn_active = \i -> match kinds[i]
        case 1i64 -> false
        case _    -> active[i]
      let fn_result = \i -> match kinds[i]
        case 1i64 -> pivots[i]
        case _    -> result[i]

      let active' = map fn_active idxs
      let result' = map fn_result idxs

      -- compact active elements for the next iteration
      let fn_compact = \(i, v) ->
        match kinds[i]
          case 0i64 -> v < pivots[i]
          case 2i64 -> v > pivots[i]
          case _ -> false

      let (ids', flat') = filter fn_compact (zip ids flat) |> unzip

      in (ks', shp', active', ids', flat', result')
  in result

def quickselect_i32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]i32) : [m]i32 =
  quickselect (-1i32) (i32.<) (i32.<=) (i32.>) ks shp flat

def quickselect_f32 [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  quickselect (-1f32) (f32.<) (f32.<=) (f32.>) ks shp flat

def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  quickselect_f32 ks shp flat
