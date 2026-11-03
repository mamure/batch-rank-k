import "../src/kdtree"

-- I'm too lazy to write more tests
def main [n][d] (height: i64) (points: [n][d]f32) : ([]f32, []i64, []i64, [][]f32) =
  let (medians, axes, leaf_shp, leaf_points) = build_kdtree height points
  in (medians, axes, leaf_shp, leaf_points)

-- ==
-- "Example"
-- compiled input {
--  2i64
--  [
--     [0f32,  2f32, 1f32],
--     [1f32,  8f32, 3f32],
--     [2f32,  4f32, 7f32],
--     [3f32,  6f32, 2f32],
--     [10f32, 1f32, 5f32],
--     [11f32, 7f32, 0f32],
--     [12f32, 3f32, 6f32],
--     [13f32, 5f32, 4f32]
-- ]}
-- output {
--   [3f32, 1f32, 11f32]
--   [0i64, 0i64]
--   [1i64, 2i64, 2i64, 3i64]
--   [
--      [0f32,  2f32, 1f32],
--      [1f32,  8f32, 3f32],
--      [2f32,  4f32, 7f32],
--      [3f32,  6f32, 2f32],
--      [10f32, 1f32, 5f32],
--      [11f32, 7f32, 0f32],
--      [12f32, 3f32, 6f32],
--      [13f32, 5f32, 4f32]
--   ]
-- }
