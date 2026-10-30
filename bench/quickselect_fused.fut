import "../src/quickselect_fused"

-- ==
-- input @ ../dataset.in
-- output @ ../dataset.out

def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  quickselect_fused ks shp flat
