-- Basically one to one with the derivation
def partition [m][n] 't
  ((<): t -> t -> bool)
  ((<=): t -> t -> bool)
  ((>): t -> t -> bool)
  (pivots: [m]t)
  (ks: [m]i64)
  (shp: [m]i64)
  (ids: [n]i64)
  (flat: [n]t)
  (result: [m]t)
  : ([m]i64, [m]i64, []i64, []t, [m]t) =
  -- classify elements relative to pivots
  let fn_lt_flags = \i v -> if shp[i] i64.> 0i64 && v < pivots[i] then 1i64 else 0i64
  let fn_lteq_flags = \i v -> if shp[i] i64.> 0i64 && v <= pivots[i] then 1i64 else 0i64

  let lt_flags = map2 fn_lt_flags ids flat
  let lteq_flags = map2 fn_lteq_flags ids flat
  let lt = hist (+) 0i64 m ids lt_flags
  let lteq = hist (+) 0i64 m ids lteq_flags
  let gt = map2 (-) shp lteq

  -- update state based on classification
  -- kind: -1 inactive, 0 go left, 1 solved, 2 go right
  let fn_kinds = \i ->
    if shp[i] i64.<= 0i64 then -1i64
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

  let fn_result = \i ->
    match kinds[i]
      case 1i64 -> pivots[i]
      case _    -> result[i]

  let result' = map fn_result idxs

  -- compact active elements for the next iteration
  let fn_compact = \(i, v) ->
    match kinds[i]
      case 0i64 -> v < pivots[i]
      case 2i64 -> v > pivots[i]
      case _ -> false

  let (ids', flat') = filter fn_compact (zip ids flat) |> unzip

  in (ks', shp', ids', flat', result')


-- Like partition but fused some maps to avoid intermediate arrays
def partition_fused [m][n] 't
  ((<): t -> t -> bool)
  ((<=): t -> t -> bool)
  ((>): t -> t -> bool)
  (pivots: [m]t)
  (ks: [m]i64)
  (shp: [m]i64)
  (ids: [n]i64)
  (flat: [n]t)
  (result: [m]t)
  : ([m]i64, [m]i64, []i64, []t, [m]t) =
  -- classify elements relative to pivots
  let fn_flags = \i v ->
    if shp[i] i64.<= 0i64 then (0i64, 0i64)
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
    if shp[i] i64.<= 0i64 then        (-1i64, 0i64, -1i64, result[i])
    else if ks[i] i64.<= lt[i] then   (0i64, lt[i], ks[i], result[i])
    else if ks[i] i64.<= lteq[i] then (1i64, 0i64, -1i64, pivots[i])
    else                              (2i64, gt[i], ks[i] - lteq[i], result[i])

  let (kinds, shp', ks', result') = map fn_update (iota m) |> unzip4

  -- compact active elements for the next iteration
  let fn_compact = \(i, v) ->
    match kinds[i]
      case 0i64 -> v < pivots[i]
      case 2i64 -> v > pivots[i]
      case _ -> false

  let (ids', flat') = filter fn_compact (zip ids flat) |> unzip

  in (ks', shp', ids', flat', result')
