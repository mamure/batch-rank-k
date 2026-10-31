def min 't ((<): t -> t -> bool) (a: t) (b: t) : t =
  if a < b then a else b

def max 't ((<): t -> t -> bool) (a: t) (b: t) : t =
  if a < b then b else a

def minmax 't ((<): t -> t -> bool) (a: t) (b: t) : (t, t) =
  if a < b then (a, b) else (b, a)

-- Turns shp into a pair of arrays containing the starting and ending indices of each segment.
-- That is:
-- starts[i] is the starting index of segment i inclusive
-- ends[i] is the ending index of segment i exclusive
-- Example:
-- shp = [3, 2, 0, 4]
-- Result:
-- starts = [0, 3, 5, 5]
-- ends   = [3, 5, 5, 9]
def get_sgm_starts_and_ends [m] (shp: [m]i64) : ([m]i64, [m]i64) =
  let ends = scan (+) 0i64 shp
  let starts = map2 (-) ends shp
  in (starts, ends)

-- Turns shp into an array containing the index of the segment each element belongs to.
-- Uses flat just for the compile time coercion of n.
-- Empty segments still increase id by 1.
-- Example:
-- shp = [3, 2, 0, 4]
-- Result:
-- [0, 0, 0, 1, 1, 3, 3, 3, 3]
def get_sgm_ids [m][n] 't (shp: [m]i64) (_flat: [n]t) : [n]i64 =
  let (starts, _) =  get_sgm_starts_and_ends shp
  let vals = scatter (replicate n 0i64) starts (iota m)
  in scan (\v1 v2 -> (if v2 != 0i64 then v2 else v1 + v2)) 0i64 vals -- sgm scan but values are also flags

-- Similar to get_sgm_starts_and_ends, but groups each segment into groups of size <=5,
-- and returns the start and ending group index of each segment for each element.
-- This is used for the smartselect median of medians pivot strategy.
-- Example:
-- shp = [6, 5, 0, 7] -> [[5, 1], [5], [0], [5, 2]]
-- Result:
-- starts = [0, 5, 6, 6]
-- ends   = [5, 6, 6, 8]
def get_sgm_group_starts_and_ends [m] (shp: [m]i64) : ([m]i64, [m]i64) =
  let num_groups = map (\s -> (s + 4i64) / 5i64) shp
  in get_sgm_starts_and_ends num_groups

-- Similar to get_sgm_ids, but groups each segment into groups of size <=5,
-- and returns the group id for each element.
-- This is used for the smartselect median of medians pivot strategy.
-- Empty segments DO NOT increase id by 1.
-- Example:
-- shp = [6, 5, 0, 7]
-- Result:
-- [0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4]
def get_sgm_group_ids [m][n] 't (shp: [m]i64) (flat: [n]t) : [n]i64 =
  if n == 0i64 then replicate n (-1i64)
  else
    let (starts, _) = get_sgm_starts_and_ends shp
    let (group_starts, _) = get_sgm_group_starts_and_ends shp
    let ids = get_sgm_ids shp flat
    let fn_group_id = \i ->
      let id = ids[i]
      in group_starts[id] + (i - starts[id]) / 5i64
    in map fn_group_id (iota n)
