def min 't ((<): t -> t -> bool) (a: t) (b: t) : t =
  if a < b then a else b

def max 't ((<): t -> t -> bool) (a: t) (b: t) : t =
  if a < b then b else a

def minmax 't ((<): t -> t -> bool) (a: t) (b: t) : (t, t) =
  if a < b then (a, b) else (b, a)

-- Produces a tuple of two arrays,
-- the first contains the starting indices of each segment,
-- and the second contains the ending indices of each segment.
-- Empty segments still produce an output, where the start and end index are equal.
-- Example:
-- shp = [3, 2, 0, 4]
-- Result:
-- starts = [0, 3, 5, 5]
-- ends   = [3, 5, 5, 9]
def get_sgm_starts_and_ends [m] (shp: [m]i64) : ([m]i64, [m]i64) =
  let ends = scan (+) 0i64 shp
  let starts = map2 (-) ends shp
  in (starts, ends)

-- Produces an array that contains the corresponding segment id for each element in flat.
-- Empty segments still increase the id by 1.
-- Example:
-- shp = [3, 2, 0, 4]
-- Result:
-- [0, 0, 0, 1, 1, 3, 3, 3, 3]
def get_sgm_ids [m] (starts: [m]i64) (n: i64) : []i64 =
  let vals = hist (max (i64.<)) 0i64 n starts (map (+ 1i64) (iota m))
  let ids = scan (\a b -> if b == 0i64 then a else b) 0i64 vals
  in map (\x -> x - 1i64) ids

-- Similar to get_sgm_ids, but groups each segment into groups of size <=5,
-- and returns the starts and ends of each group.
-- Empty segments and empty groups DO NOT produce any output.
-- Example:
-- shp = [6, 5, 0, 7] -> [[5, 1], [5], [0], [5, 2]]
-- Result:
-- starts = [0, 5, 6,  11, 16]
-- ends   = [5, 6, 11, 16, 18]
def get_group_starts_and_ends [n] (g_ids: [n]i64) (n': i64) : ([]i64, []i64) =
  let g_starts = hist (min (i64.<)) n n' g_ids (iota n)
  let sizes = hist (+) 0i64 n' g_ids (replicate n 1i64)
  let g_ends = map2 (+) g_starts sizes
  in (g_starts, g_ends)

-- Similar to get_sgm_ids, but groups each segment into groups of size <=5,
-- and returns the group id for every element in flat.
-- Empty segments and empty groups DO NOT increase the id by 1.
-- Example:
-- shp = [6, 5, 0, 7]
-- Result:
-- [0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4]
def get_group_ids [m][n] (starts: [m]i64) (starts': [m]i64) (ids: [n]i64) : [n]i64 =
  if n == 0i64 then replicate n 0
  else
    let fn_group_id = \i -> starts'[ids[i]] + (i - starts[ids[i]]) / 5i64
    in map fn_group_id (iota n)
