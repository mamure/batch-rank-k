import "shared"
import "smartselect"


def get_max_spread_axis [n][d] (points: [n][d]f32) : i64 =
  if n == 0i64 || d == 0i64 then 0i64
  else
    let fn_spread = \j ->
      let ds = map (\p -> p[j]) points
      let min = reduce (min (<)) ds[0] ds
      let max = reduce (max (<)) ds[0] ds
      in max - min

    let fn_max = \(s1, d1) (s2, d2) ->
      if s2 > s1 then (s2, d2) else (s1, d1)

    let spreads = map fn_spread (iota d)
    let (_, dim) = reduce fn_max (-1f32, 0i64) (zip spreads (iota d))
    in dim

def get_medians [m][n][d] (shp: [m]i64) (points: [n][d]f32) (axis: i64) : [m]f32 =
  let proj = map (\p -> p[axis]) points
  let ks = map (\s -> (s + 1i64) / 2i64) shp
  in smartselect_f32 ks shp proj

def partition2 [m][n][d] (shp: [m]i64) (points: [n][d]f32) (medians: [m]f32) (axis: i64) : ([m*2]i64, [n][d]f32) =
  let (starts, _) = get_sgm_starts_and_ends shp
  let ids = get_sgm_ids starts n

  -- Determine which side each point belongs to.
  let left_flags  = map2 (\id p -> if p[axis] < medians[id] then 1i64 else 0i64) ids points
  let right_flags = map (\lt -> if lt == 1i64 then 0i64 else 1i64) left_flags
  let num_left = hist (+) 0i64 m ids left_flags
  let num_right = map2 (-) shp num_left

  -- Interleave left and right child sizes.
  let shp' = map2(\l r -> [l, r]) num_left num_right |> flatten

  -- Determine the new positions in the flat array.
  let fn_offsets = \(id1, l1, r1) (id2, l2, r2) ->
    if id1 == id2 then (id2, l1 + l2, r1 + r2) else (id2, l2, r2)

  let fn_dest = \(id, lo, ro) lf ->
    if lf == 1i64 then starts[id] + lo - 1i64
    else               starts[id] + num_left[id] + ro - 1i64

  let offsets = scan fn_offsets (-1i64, 0i64, 0i64) (zip3 ids left_flags right_flags)
  let dest = map2 fn_dest offsets left_flags

  -- Scatter points into their partitioned positions.
  let points' = scatter (replicate n (replicate d 0f32)) dest points
  in (shp', points')


-- Build a kdtree with a given height from a set of points.
-- Returns
--   - the medians of each internal node in breadth first order,
--   - the axes along which each level was split,
--   - the shape of the leaf nodes,
--   - the points in the leaf nodes (flattened).
def build_kdtree [n][d] (height: i64) (points: [n][d]f32) : ([]f32, []i64, []i64, [][]f32) =
  let num_leaves = reduce (*) 1i64 (replicate height 2i64)
  let num_internal = num_leaves - 1i64

  let shp = [n]
  let medians = replicate num_internal 0f32
  let axes = replicate height 0i64

  let (_, _, leaf_shp, leaf_points, medians, axes) =
    loop (level, active, shp, points, medians, axes) = (0i64, 1i64, shp, points, medians, axes)
    while level < height do
      let axis = get_max_spread_axis points
      let pivots = get_medians shp points axis

      -- Save medians using breadth first indexing.
      let indices = map (+ (active - 1i64)) (iota active)
      let medians' = scatter medians indices pivots[0:active]

      -- Partition all segments.
      let (shp', points') = partition2 shp points pivots axis
      let axes' = axes with [level] = axis
      in (level + 1i64, active * 2i64, shp', points', medians', axes')

  in (medians, axes, leaf_shp, leaf_points)
