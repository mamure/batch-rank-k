import "src/reference"
import "src/quickselect"
import "src/shared"

-- m is number of segments.
-- n is number of elements.
-- ks stores 1-based ranks (k=1 is min elem, k=0 is invalid). Length m.
-- shp stores segment lengths. Length m.
-- ids stores the segment each element belongs to. Length n.
-- flat stores all segment elements flattened. Length n.

entry run_quickselect [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let ids = get_sgm_ids shp flat
  in rank_search_quickselect ks shp ids flat

entry run_reference [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  rank_search_reference ks shp flat
