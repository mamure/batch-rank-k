import "shared"

-- Flattened batch rank-search-k.
-- Based on the handout pseudo code, but transformed to allow irregular arrays via flattening.
-- It effectively uses quickselect with the pivot is chosen as the last element in each segment
-- This is for simplicity as it avoids dealing with random number generation
-- and it gives the same asymptotic complexity O(n^2),
-- however an adversarial input is trivial to construct.
-- It does not handle NaN values.


-- Always choose the last element as pivot for each segment.
def choose_pivots [m][n] (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let (_, ends) =  get_sgm_starts_and_ends shp
  in map
       (\i -> if shp[i] > 0i64 then flat[ends[i] - 1i64] else 0f32)
       (iota m)

-- Count the number of elements less than, equal to, and greater than the pivot for each segment.
-- TODO maybe apply some map fusion
def classify_counts [m][n] (active: [m]bool) (pivots: [m]f32) (ids: [n]i64) (flat: [n]f32)
    : ([m]i64, [m]i64, [m]i64) =
  let less_flags =
    map2 (\sgm x -> if active[sgm] && x < pivots[sgm] then 1i64 else 0i64) ids flat
  let equal_flags =
    map2 (\sgm x -> if active[sgm] && x == pivots[sgm] then 1i64 else 0i64) ids flat
  let greater_flags =
    map2 (\sgm x -> if active[sgm] && x > pivots[sgm] then 1i64 else 0i64) ids flat
  let less = hist (+) 0i64 m ids less_flags
  let equal = hist (+) 0i64 m ids equal_flags
  let greater = hist (+) 0i64 m ids greater_flags
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
  (ids: [n]i64)
  (flat: [n]f32)
  : ([]i64, []f32) =
  let pairs = zip ids flat
  let kept =
    filter
      (\(sgm, x) ->
        if kinds[sgm] == 0i64 then x < pivots[sgm]
        else if kinds[sgm] == 2i64 then x > pivots[sgm]
        else false)
      pairs
  in (map (.0) kept, map (.1) kept)

def rank_search_quickselect [m][n] (ks: [m]i64) (shp: [m]i64) (ids: [n]i64) (flat: [n]f32) : [m]f32 =
  let initial_result = replicate m 0f32
  let initial_active = map (> 0i64) shp
  let (_, _, _, _, _, result) =
    loop (ks_cur, shp_cur, active_cur, ids_cur, flat_cur, result_cur) =
         (ks, shp, initial_active, ids, flat, initial_result)
    while (length flat_cur > 0 && reduce (||) false active_cur) do
      let pivots = choose_pivots shp_cur flat_cur
      let (less, equal, greater) = classify_counts active_cur pivots ids_cur flat_cur
      let (kinds, ks_next, shp_next, active_next, result_next) =
        update_state ks_cur active_cur pivots less equal greater result_cur
      let (ids_next, flat_next) = filter_active_elements kinds pivots ids_cur flat_cur
      in (ks_next, shp_next, active_next, ids_next, flat_next, result_next)
  in result
