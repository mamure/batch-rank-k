import "src/shared"
import "src/pivots"

def main : i32 =
  let shp = [6i64, 5i64, 0i64, 7i64]
  let n = reduce (+) 0i64 shp
  let flat = replicate n 0i64
  let ids = get_sgm_ids shp flat
  let gids = get_sgm_group_ids shp flat

  let _ = trace shp
  let _ = trace ids
  let _ = trace gids
  let _ = trace 0

  let shp' = map (\s -> (s + 4i64) / 5i64) shp
  let num_groups = last gids + 1i64

  let _ = trace shp'
  let _ = trace num_groups
  let _ = trace 0

  let (starts, ends) = get_sgm_starts_and_ends shp
  let gends = scan (+) 0i64 shp'
  let gstarts = map2 (-) ends shp'
  let _ = trace gstarts
  let _ = trace gends
  let _ = trace 0

  -- TODO use hist or extract from get_sgm_group_ids
  let group_sizes =
    map (\g -> reduce (+) 0i64 (map (\id -> if id == g then 1i64 else 0i64) gids))
        (iota num_groups)

  let _ = trace group_sizes
  let _ = trace 0

  let elem_idx_in_group = map2 (\i id -> (i - starts[id]) % 5i64) (iota n) ids

  let _ = trace elem_idx_in_group let _ = trace 0

  let group_values =
    scatter
      (replicate (num_groups * 5) 0f32)
      (map2 (\g i -> g * 5 + i) gids elem_idx_in_group)
      flat

--
  --let a =  map (\g -> median_of_lteq_5 (<) (group_values[g][0 : group_sizes[g]]))
  --       (iota num_groups)

  in 0i32
