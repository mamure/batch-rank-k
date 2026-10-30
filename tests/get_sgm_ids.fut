import "../src/shared"

-- Becuase Futhark's testing framework seemingly does not support empty arrays,
-- We prepend every array with a dummy value (-1) to avoid empty arrays in the input and output.
-- These are removed/added before and after the actual computation.
def main [m] (shp: [m]i64) : []i64 =
    let shp = shp[1 : m]
    let flat = (replicate (reduce (+) 0i64 shp) 0f32)
    let res = get_sgm_ids shp flat
    in [-1] ++ res


-- ==
-- "Empty input"
-- compiled input { [-1i64] }
-- output { [-1i64] }
--
-- "Basic example"
-- compiled input { [-1i64,3i64,2i64,4i64] }
-- output { [-1i64,0i64,0i64,0i64,1i64,1i64,2i64,2i64,2i64,2i64] }
--
-- "Single segment of length one"
-- compiled input { [-1i64,1i64] }
-- output { [-1i64,0i64] }
--
-- "Single segment of length five"
-- compiled input { [-1i64,5i64] }
-- output { [-1i64,0i64,0i64,0i64,0i64,0i64] }
--
-- "Multiple segments of length one"
-- compiled input { [-1i64,1i64,1i64,1i64,1i64] }
-- output { [-1i64,0i64,1i64,2i64,3i64] }
--
-- "Multiple equal-length segments"
-- compiled input { [-1i64,2i64,2i64,2i64,2i64] }
-- output { [-1i64,0i64,0i64,1i64,1i64,2i64,2i64,3i64,3i64] }
--
-- "Single empty segment"
-- compiled input { [-1i64,0i64] }
-- output { [-1i64] }
--
-- "All segments empty"
-- compiled input { [-1i64,0i64,0i64,0i64] }
-- output { [-1i64] }
--
-- "Empty segment in the middle"
-- compiled input { [-1i64,3i64,0i64,2i64] }
-- output { [-1i64,0i64,0i64,0i64,2i64,2i64] }
--
-- "Empty segments at the beginning and middle"
-- compiled input { [-1i64,0i64,3i64,0i64,2i64,0i64] }
-- output { [-1i64,1i64,1i64,1i64,3i64,3i64] }
--
-- "Multiple consecutive empty segments"
-- compiled input { [-1i64,2i64,0i64,0i64,0i64,4i64] }
-- output { [-1i64,0i64,0i64,4i64,4i64,4i64,4i64] }
--
-- "Empty segments surrounding a nonempty segment"
-- compiled input { [-1i64,0i64,0i64,5i64,0i64] }
-- output { [-1i64,2i64,2i64,2i64,2i64,2i64] }
--
-- "Alternating empty and nonempty segments"
-- compiled input { [-1i64,1i64,0i64,1i64,0i64,1i64] }
-- output { [-1i64,0i64,2i64,4i64] }
--
-- "Uneven segment lengths"
-- compiled input { [-1i64,7i64,1i64,3i64,2i64] }
-- output { [-1i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,1i64,2i64,2i64,2i64,3i64,3i64] }
--
-- "Large uneven segments with an empty segment"
-- compiled input { [-1i64,10i64,5i64,0i64,8i64] }
-- output { [-1i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,1i64,1i64,1i64,1i64,1i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64] }
--
-- "Increasing segment lengths"
-- compiled input { [-1i64,1i64,2i64,3i64,4i64,5i64] }
-- output { [-1i64,0i64,1i64,1i64,2i64,2i64,2i64,3i64,3i64,3i64,3i64,4i64,4i64,4i64,4i64,4i64] }
--
-- "Decreasing segment lengths"
-- compiled input { [-1i64,5i64,4i64,3i64,2i64,1i64] }
-- output { [-1i64,0i64,0i64,0i64,0i64,0i64,1i64,1i64,1i64,1i64,2i64,2i64,2i64,3i64,3i64,4i64] }
--
-- "Many equal-length segments"
-- compiled input { [-1i64,10i64,10i64,10i64,10i64,10i64] }
-- output { [-1i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,0i64,1i64,1i64,1i64,1i64,1i64,1i64,1i64,1i64,1i64,1i64,2i64,2i64,2i64,2i64,2i64,2i64,2i64,2i64,2i64,2i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64,3i64,4i64,4i64,4i64,4i64,4i64,4i64,4i64,4i64,4i64,4i64] }
--
-- "Increasing lengths across many segments"
-- compiled input { [-1i64,0i64,1i64,2i64,3i64,4i64,5i64,6i64,7i64,8i64] }
-- output { [-1i64,1i64,2i64,2i64,3i64,3i64,3i64,4i64,4i64,4i64,4i64,5i64,5i64,5i64,5i64,5i64,6i64,6i64,6i64,6i64,6i64,6i64,7i64,7i64,7i64,7i64,7i64,7i64,7i64,8i64,8i64,8i64,8i64,8i64,8i64,8i64,8i64] }
