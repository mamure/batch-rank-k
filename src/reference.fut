import "shared"
import "../lib/github.com/diku-dk/sorts/radix_sort"

-- Reference baseline.
-- Sort each segment independently, then select its 1-based k-th element.

def reference [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : [m]f32 =
  let (starts, ends) = get_sgm_starts_and_ends shp
  in map
       (\i ->
         if shp[i] > 0i64
         then
           let segment = flat[starts[i] : ends[i]]
           let sorted = radix_sort_float f32.num_bits f32.get_bit segment
           in sorted[ks[i] - 1i64]
         else -1f32)
       (iota m)


def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  reference ks shp flat
