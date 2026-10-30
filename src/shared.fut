-- Turns shp into a pair of arrays containing the starting and ending indices of each segment.
-- That is:
-- starts[i] is the starting index of segment i inclusive
-- ends[i] is the ending index of segment i exclusive
-- Example:
-- shp = [3, 2, 4]
-- Result:
-- starts = [0, 3, 5]
-- ends   = [3, 5, 9]
def get_sgm_starts_and_ends [m] (shp: [m]i64) : ([m]i64, [m]i64) =
  let ends = scan (+) 0i64 shp
  let starts = map2 (-) ends shp
  in (starts, ends)

-- Turns shp into an array containing the index of the segment each element belongs to.
-- Uses flat just for the compile time coercion of n.
-- Example:
-- shp = [3, 2, 4]
-- Result:
-- [0, 0, 0, 1, 1, 2, 2, 2, 2]
def get_sgm_ids [m][n] 't (shp: [m]i64) (_flat: [n]t) : [n]i64 =
  let (starts, _) =  get_sgm_starts_and_ends shp
  let vals = scatter (replicate n 0i64) starts (iota m)
  in scan (\v1 v2 -> (if v2 != 0i64 then v2 else v1 + v2)) 0i64 vals -- sgm scan but values are also flags


def choose_pivots_last [m][n] 't (ne: t) (shp: [m]i64) (flat: [n]t) : [m]t =
  let (_, ends) = get_sgm_starts_and_ends shp
  in map
       (\i -> if shp[i] == 0i64 then ne
              else flat[ends[i] - 1i64] )
       (iota m)

def choose_pivots_first [m][n] 't (ne: t) (shp: [m]i64) (flat: [n]t) : [m]t =
  let (starts, _) = get_sgm_starts_and_ends shp
  in map
       (\i -> if shp[i] == 0i64 then ne
              else flat[starts[i]] )
       (iota m)

def choose_pivots_middle [m][n] 't (ne: t) (shp: [m]i64) (flat: [n]t) : [m]t =
  let (starts, ends) = get_sgm_starts_and_ends shp
  in map
       (\i -> if shp[i] == 0i64 then ne
              else flat[starts[i] + (ends[i] - starts[i]) / 2i64] )
       (iota m)
