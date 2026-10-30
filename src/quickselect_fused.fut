import "shared"

-- Like quickselect,
-- but manually fuses maps to avoid creating intermediate arrays.

def quickselect_fused [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let ids = get_sgm_ids shp flat
  let result = replicate m (-1f32)
  let active = map (> 0i64) shp
  let (_, _, _, _, _, result) =
    loop (ks, shp, active, ids, flat, result) = (ks, shp, active, ids, flat, result)
    while (any (== true) active) do
      -- select pivots
      let pivots = choose_pivots_last shp flat

      -- classify elements relative to pivots
      let fn_flags = \i v ->
        if !active[i] then (0i64, 0i64)
        else
          let a = if v < pivots[i] then 1i64 else 0i64
          let b = if v <= pivots[i] then 1i64 else 0i64
          in (a, b)

      let (lt_flags, lteq_flags) = map2 fn_flags ids flat |> unzip
      let lt = hist (+) 0i64 m ids lt_flags
      let lteq = hist (+) 0i64 m ids lteq_flags
      let gt = map2 (-) shp lteq

      -- update state based on classification
      -- kind: -1 inactive, 0 go left, 1 solved, 2 go right
      let fn_update = \i ->
        if !active[i] then            (-1i64, 0i64, -1i64, false, result[i])
        else if ks[i] <= lt[i] then   (0i64, lt[i], ks[i], true, result[i])
        else if ks[i] <= lteq[i] then (1i64, 0i64, -1i64, false, pivots[i])
        else                          (2i64, gt[i], ks[i] - lteq[i], true, result[i])

      let (kinds, shp', ks', active', result') = map fn_update (iota m) |> unzip5

      -- compact active elements for the next iteration
      let fn_compact = \(i, x) ->
        match kinds[i]
          case 0i64 -> x < pivots[i]
          case 2i64 -> x > pivots[i]
          case _ -> false

      let (ids', flat') = filter fn_compact (zip ids flat) |> unzip

      in (ks', shp', active', ids', flat', result')
  in result


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  quickselect_fused ks shp flat
