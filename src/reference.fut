import "shared"

-- Reference sequential baseline
-- Sort each segment independently, then select its 1-based k-th element.
-- This should only be run on the CPU.

def insertion_sort [n] (xs: [n]f32) : [n]f32 =
  loop sorted = copy xs for i < n do
    let key = sorted[i]
    let (j, sorted) =
      loop (j, sorted) = (i, sorted)
      while j > 0i64 && sorted[j - 1] > key do
        (j - 1i64, sorted with [j] = sorted[j - 1])
    in sorted with [j] = key

def rank_search_reference [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let (starts, ends) = get_sgm_starts_and_ends shp
  in map
       (\i ->
         if shp[i] > 0i64
         then
           let segment = flat[starts[i] : ends[i]]
           let sorted = insertion_sort segment
           in sorted[ks[i] - 1i64]
         else 0f32)
       (iota m)
