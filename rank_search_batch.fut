-- Flattened batch rank-search-k over a shape+flat representation.
--
-- Conventions:
-- * ks uses 1-based ranks (k=1 means minimum element in the segment)
-- * shp describes segment lengths
-- * flat stores all segment elements in row-major segmented order

def exclusive_offsets [m] (shp: [m]i64) : [m]i64 =
  map2 (-) (scan (+) 0i64 shp) shp

def pivots_from_last [m][n] (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let offs = exclusive_offsets shp
  let idxs = iota m
  in map
       (\i ->
         if shp[i] > 0i64
         then flat[offs[i] + shp[i] - 1]
         else 0f32)
       idxs

def classify_counts [m][n] (active: [m]bool) (pivots: [m]f32) (ii1: [n]i64) (flat: [n]f32)
    : ([m]i64, [m]i64, [m]i64) =
  let less_flags =
    map2
      (\seg x -> if active[seg] && x < pivots[seg] then 1i64 else 0i64)
      ii1
      flat
  let equal_flags =
    map2
      (\seg x -> if active[seg] && x == pivots[seg] then 1i64 else 0i64)
      ii1
      flat
  let greater_flags =
    map2
      (\seg x -> if active[seg] && x > pivots[seg] then 1i64 else 0i64)
      ii1
      flat
  let less = hist (+) 0i64 m ii1 less_flags
  let equal = hist (+) 0i64 m ii1 equal_flags
  let greater = hist (+) 0i64 m ii1 greater_flags
  in (less, equal, greater)

-- kind: -1 inactive, 0 recurse-left, 1 solved, 2 recurse-right
def update_state [m]
  (ks: [m]i64)
  (active: [m]bool)
  (pivots: [m]f32)
  (less: [m]i64)
  (equal: [m]i64)
  (greater: [m]i64)
  (result: [m]f32)
  : ([m]i64, [m]i64, [m]i64, [m]bool, [m]f32) =
  let idxs = iota m
  let kinds =
    map
      (\i ->
        if !active[i] then -1i64
        else if ks[i] <= less[i] then 0i64
        else if ks[i] <= less[i] + equal[i] then 1i64
        else 2i64)
      idxs
  let new_shp =
    map
      (\i ->
        if kinds[i] == 0i64 then less[i]
        else if kinds[i] == 2i64 then greater[i]
        else 0i64)
      idxs
  let new_ks =
    map
      (\i ->
        if kinds[i] == 0i64 then ks[i]
        else if kinds[i] == 2i64 then ks[i] - less[i] - equal[i]
        else -1i64)
      idxs
  let new_active = map (> 0i64) new_shp
  let new_result =
    map
      (\i -> if kinds[i] == 1i64 then pivots[i] else result[i])
      idxs
  in (kinds, new_ks, new_shp, new_active, new_result)

def filter_active_elements [m][n]
  (kinds: [m]i64)
  (pivots: [m]f32)
  (ii1: [n]i64)
  (flat: [n]f32)
  : ([]i64, []f32) =
  let pairs = zip ii1 flat
  let kept =
    filter
      (\(seg, x) ->
        if kinds[seg] == 0i64 then x < pivots[seg]
        else if kinds[seg] == 2i64 then x > pivots[seg]
        else false)
      pairs
  in (map (.0) kept, map (.1) kept)

def rank_search_batch [m][n] (ks: [m]i64) (shp: [m]i64) (ii1: [n]i64) (flat: [n]f32) : [m]f32 =
  let initial_result = replicate m 0f32
  let initial_active = map (> 0i64) shp
  let (_, _, _, _, _, result) =
    loop (ks_cur, shp_cur, active_cur, ii1_cur, flat_cur, result_cur) =
         (ks, shp, initial_active, ii1, flat, initial_result)
    while (length flat_cur > 0 && reduce (||) false active_cur) do
      let pivots = pivots_from_last shp_cur flat_cur
      let (less, equal, greater) = classify_counts active_cur pivots ii1_cur flat_cur
      let (kinds, ks_next, shp_next, active_next, result_next) =
        update_state ks_cur active_cur pivots less equal greater result_cur
      let (ii1_next, flat_next) = filter_active_elements kinds pivots ii1_cur flat_cur
      in (ks_next, shp_next, active_next, ii1_next, flat_next, result_next)
  in result

entry run_batch_rank_search [m][n]
  (ks: [m]i64)
  (shp: [m]i64)
  (ii1: [n]i64)
  (flat: [n]f32)
  : [m]f32 =
  rank_search_batch ks shp ii1 flat
