import subprocess
import random
import run_bench


SEED = 42
BACKEND = "c"


def run_test(variant):
    print(f"\nTesting {variant}:")
    subprocess.run(
        ["futhark", "test", f"--backend={BACKEND}", f"tests/{variant}.fut"],
        check=True
    )

if __name__ == "__main__":
    run_bench.BACKEND = BACKEND
    run_bench.SEED = SEED
    random.seed(SEED)

    run_bench.compile("reference")
    run_bench.make_random_input(m=1000, shp_min=0, shp_max=10)
    run_bench.make_output()

    print(f"Running tests with backend {BACKEND} and seed {SEED}...")

    run_test("get_sgm_starts_and_ends")
    run_test("get_sgm_ids")

    run_test("get_group_ids")
    run_test("get_group_starts_and_ends")

    run_test("kdtree_partition2")
    run_test("kdtree")

    run_test("reference")
    run_test("quickselect")
    run_test("quickselect_fused")
    run_test("smartselect")
