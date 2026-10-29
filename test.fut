import "src/shared"
import "src/reference"
import "src/quickselect"

def main : i32 =
    let ks = [1, 2, 3]
    let shp = [3, 2, 4]
    let flat = map f32.i64 (iota 9)
    let _= trace (ks)
    let _= trace (shp)
    let _= trace (flat)

    let _= trace 0

    let (starts, ends) = get_sgm_starts_and_ends shp
    let _ = trace (starts)
    let _ = trace (ends)

    let _= trace 0

    let ids = get_sgm_ids shp flat
    let _ = trace (ids)
    let _ = trace (rank_search_reference ks shp flat)
    let _ = trace (rank_search_quickselect ks shp ids flat)
    in 0
