import subprocess
import random

SEED = 42
BACKEND = "c"

DATASET_IN = "dataset.in"
DATASET_OUT = "dataset.out"

def write_dataset(ks, shp, flat):
    with open(DATASET_IN, "w") as f:
        f.write("[" + ",".join(map(lambda x: f"{x}i64", ks)) + "]\n")
        f.write("[" + ",".join(map(lambda x: f"{x}i64", shp)) + "]\n")
        f.write("[" + ",".join(map(lambda x: f"{x}f32", flat)) + "]\n")

def make_random_input(seed, m, shp_max):
    random.seed(seed)
    shp = [random.randint(0, shp_max) for _ in range(m)]
    ks = [random.randint(0, max(shp[i] - 1, 0)) + 1 for i in range(m)]
    flat = [random.uniform(-1e9, 1e9) for _ in range(sum(shp))]
    write_dataset(ks, shp, flat)

# For quickselect with last or first element as pivot,
# sorted input gives the worst case.
def make_adversarial_input(seed, m, shp_max):
    random.seed(seed)
    shp = [random.randint(0, shp_max) for _ in range(m)]
    ks = [random.randint(0, max(shp[i] - 1, 0)) + 1 for i in range(m)]
    flat = [float(i) for i in range(sum(shp))]
    write_dataset(ks, shp, flat)

def make_output():
    subprocess.run(
        ["futhark", BACKEND, "src/reference.fut"],
        check=True,
    )
    with open(DATASET_IN, "rb") as stdin:
        with open(DATASET_OUT, "wb") as stdout:
            subprocess.run(
                ["src/reference"],
                stdin=stdin,
                stdout=stdout,
                check=True,
            )

def run_bench(variant):
    subprocess.run(["futhark", "bench", f"bench/{variant}.fut"], check=True)

def parse_output():
    # TODO parse the stdout of the benchmark to extract the metrics
    pass

if __name__ == "__main__":
    # TODO run multiple times with increasing m and maybe shape_max
    # TODO collect the metrics into a csv and plot them
    make_random_input(seed=SEED, m=1000, shp_max=1000)
    make_output()
    run_bench("reference")
    run_bench("quickselect")
    run_bench("quickselect_fused")
    #run_bench("smartselect")
