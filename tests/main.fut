import "../src/quickselect"
import "../src/reference"

-- Becuase Futhark's testing framework seemingly does not support empty arrays,
-- We prepend every array with a dummy value (-1) to avoid empty arrays in the input and output.
-- These are removed/added before and after the actual computation.
def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
    let shp = shp[1 : m]
    let ks = ks[1 : m]
    let flat = flat[1 : n]
    --let res = reference ks shp flat
    let res = quickselect ks shp flat
    in [-1] ++ res


-- ==
-- "Empty input"
-- compiled input { [-1i64] [-1i64] [-1f32] }
-- output { [-1f32] }
--
-- "Larger flat than sum of shape"
-- compiled input { [-1i64] [-1i64] [-1f32, 1f32, 2f32] }
-- output { [-1f32] }
--
-- "Larger flat than sum of shape with empty segments"
-- compiled input { [-1i64, -1i64] [-1i64, 0i64] [-1f32, 1f32, 2f32] }
-- output { [-1f32, -1f32] }
--
-- "Basic example"
-- compiled input { [-1i64,1i64,2i64,3i64] [-1i64, 3i64, 2i64, 4i64] [-1f32, 0f32, 1f32, 2f32, 3f32, 4f32, 5f32, 6f32, 7f32, 8f32] }
-- output { [-1f32,0f32,4f32,7f32] }
--
-- "Single element segments"
-- compiled input { [-1i64,1i64,1i64,1i64] [-1i64,1i64,1i64,1i64] [-1f32,5f32,2f32,9f32] }
-- output { [-1f32,5f32,2f32,9f32] }
--
-- "Select first element"
-- compiled input { [-1i64,1i64] [-1i64,4i64] [-1f32,8f32,3f32,6f32,1f32] }
-- output { [-1f32,1f32] }
--
-- "Select last element"
-- compiled input { [-1i64,4i64] [-1i64,4i64] [-1f32,8f32,3f32,6f32,1f32] }
-- output { [-1f32,8f32] }
--
-- "Select middle element"
-- compiled input { [-1i64,2i64] [-1i64,4i64] [-1f32,8f32,3f32,6f32,1f32] }
-- output { [-1f32,3f32] }
--
-- "Unsorted segments"
-- compiled input { [-1i64,2i64,3i64] [-1i64,4i64,3i64] [-1f32,9f32,1f32,7f32,3f32,8f32,2f32,6f32] }
-- output { [-1f32,3f32,8f32] }
--
-- "Repeated values"
-- compiled input { [-1i64,2i64,3i64] [-1i64,5i64,4i64] [-1f32,4f32,2f32,2f32,8f32,5f32,5f32,1f32,5f32,5f32] }
-- output { [-1f32,2f32,5f32] }
--
-- "Negative and positive values"
-- compiled input { [-1i64,2i64,3i64] [-1i64,3i64,3i64] [-1f32,-5f32,3f32,0f32,-2f32,8f32,1f32] }
-- output { [-1f32,0f32,8f32] }
--
-- "Different ranks per segment"
-- compiled input { [-1i64,1i64,3i64,2i64] [-1i64,4i64,5i64,3i64] [-1f32,7f32,2f32,9f32,1f32,8f32,3f32,6f32,4f32,5f32,0f32,10f32,11f32] }
-- output { [-1f32,1f32,5f32,10f32] }
--
-- "Empty segment at beginning"
-- compiled input { [-1i64,-1i64,1i64,2i64] [-1i64,0i64,3i64,2i64] [-1f32,7f32,2f32,9f32,1f32,8f32] }
-- output { [-1f32,-1f32,2f32,8f32] }
--
-- "Empty segment in middle"
-- compiled input { [-1i64,1i64,-1i64,2i64] [-1i64,3i64,0i64,2i64] [-1f32,7f32,2f32,9f32,1f32,8f32] }
-- output { [-1f32,2f32,-1f32,8f32] }
--
-- "Empty segments at beginning and end"
-- compiled input { [-1i64,-1i64,1i64,-1i64] [-1i64,0i64,3i64,0i64] [-1f32,7f32,2f32,9f32] }
-- output { [-1f32,-1f32,2f32,-1f32] }
