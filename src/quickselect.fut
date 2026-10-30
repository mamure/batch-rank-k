import "shared"

-- Flattened batch rank-search-k.
-- Based on the handout pseudo code, but transformed to allow irregular arrays via flattening.
-- It uses quickselect with the pivot chosen as the last element in each segment
-- This is for simplicity as it avoids dealing with random number generation
-- and it gives the same asymptotic complexity O(n^2),
-- however an adversarial input is trivial to construct.

def choose_pivots [m][n] (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let ends = scan (+) 0i64 shp
  in map
       (\i -> if shp[i] > 0i64 then flat[ends[i] - 1i64] else 0f32)
       (iota m)

def quickselect [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let ids = get_sgm_ids shp flat
  let result = replicate m (-1f32)
  let active = map (> 0i64) shp
  let (_, _, _, _, _, result) =
    loop (ks, shp, active, ids, flat, result) = (ks, shp, active, ids, flat, result)
    while (any (== true) active) do
      -- select pivots
      let pivots = choose_pivots shp flat

      -- classify elements relative to pivots
      let lt_flags = map2 (\i v -> if active[i] && v < pivots[i] then 1i64 else 0i64) ids flat
      let lteq_flags = map2 (\i v -> if active[i] && v <= pivots[i] then 1i64 else 0i64) ids flat
      let lt = hist (+) 0i64 m ids lt_flags
      let lteq = hist (+) 0i64 m ids lteq_flags
      let gt = map2 (-) shp lteq

      -- update state based on classification
      -- kind: -1 inactive, 0 go left, 1 solved, 2 go right
      let idxs = iota m
      let kinds =idxs |> map (\i ->
          if !active[i] then -1i64
          else if ks[i] <= lt[i] then 0i64
          else if ks[i] <= lteq[i] then 1i64
          else 2i64)
      let shp' = idxs |> map (\i -> match kinds[i]
          case 0i64 -> lt[i]
          case 2i64 -> gt[i]
          case _    -> 0i64)
      let ks' = idxs |> map (\i -> match kinds[i]
          case 0i64 -> ks[i]
          case 2i64 -> ks[i] - lteq[i]
          case _    -> -1i64)
      let active' = idxs |> map (\i -> active[i] && kinds[i] != 1)
      let result' = idxs |> map (\i -> if kinds[i] == 1i64 then pivots[i] else result[i])

      -- compact active elements for the next iteration
      let (ids', flat') =
        let keep = (zip ids flat) |>
          filter (\(i, x) -> match kinds[i]
            case 0i64 -> x < pivots[i]
            case 2i64 -> x > pivots[i]
            case _ -> false)
        in unzip keep

      in (ks', shp', active', ids', flat', result')
  in result


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  quickselect ks shp flat
