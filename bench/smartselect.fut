import "../src/smartselect"

-- ==
-- "dataset" input @ ../dataset.in
-- output @ ../dataset.out

def main [m][n] (ks: [m]i64) (shp: [m]i64) (flat: [n]f32) : []f32 =
  smartselect_f32 ks shp flat
