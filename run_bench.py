import subprocess
import random
import re

SEED = 42
BACKEND = "c"

CSV = "benchmarks.csv"

DATASET_IN = "dataset.in"
DATASET_OUT = "dataset.out"

def write_dataset(ks, shp, flat):
    with open(DATASET_IN, "w") as f:
        f.write("[" + ",".join(map(lambda x: f"{x}i64", ks)) + "]\n")
        f.write("[" + ",".join(map(lambda x: f"{x}i64", shp)) + "]\n")
        f.write("[" + ",".join(map(lambda x: f"{x}f32", flat)) + "]\n")

def make_random_input(m, shp_max):
    shp = [random.randint(0, shp_max) for _ in range(m)]
    ks = [random.randint(0, max(shp[i] - 1, 0)) + 1 for i in range(m)]
    flat = [random.uniform(-1e9, 1e9) for _ in range(sum(shp))]
    write_dataset(ks, shp, flat)

# For quickselect with last or first element as pivot,
# sorted input gives the worst case.
def make_adversarial_input(m, shp_max):
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

def parse_output(stdout):
    pat = re.compile(r"^dataset:\s+([+-]?(?:[0-9]*[.])?[0-9]+)μs\s+\(\s*95%\s+CI:\s+\[\s*([+-]?(?:[0-9]*[.])?[0-9]+),\s*([+-]?(?:[0-9]*[.])?[0-9]+)\s*\]\s*\)$")
    for line in stdout.splitlines():
        match = pat.match(line)
        if match:
            time = float(match.group(1))
            ci_lo = float(match.group(2))
            ci_hi = float(match.group(3))
            return time, ci_lo, ci_hi

def run_bench(variant, m, shape_max):
    print(f"\nBenchmarking {variant} ...")
    stdout = subprocess.run(["futhark", "bench", f"bench/{variant}.fut"], check=True, capture_output=True, text=True)
    time, ci_lo, ci_hi = parse_output(stdout.stdout)
    print(f"Time: {time:.2f} μs (95% CI: [{ci_lo:.2f}, {ci_hi:.2f}])")
    with open(CSV, "a") as csv:
        csv.write(f"{m},{shape_max},{variant},{time},{ci_lo},{ci_hi}\n")


def parse_output_cub():
    # TODO parse the stdout of the benchmark to extract the metrics
    pass

def run_bench_cub():
    subprocess.run(["nvcc", "-O3", "-o", "reference_cub", "src/reference_cub.cu"], check=True)
    for i in range(10):
        subprocess.run(["./reference_cub"], check=True)
        parse_output_cub()


if __name__ == "__main__":
    random.seed(SEED)

    csv = open(CSV, "w")
    csv.write("m,shape_max,variant,time,ci_lo,ci_hi\n")
    csv.close()

    hyperparams = [
        (1000, 10),
        (1000, 100),
        (10, 1000),
        (100, 1000),
        (1000, 1000),

        (10000, 10),
        (10000, 100),
        (10000, 1000),
        (10, 10000),
        (100, 10000),
        (1000, 10000),
        (10000, 10000),

        (100000, 10),
        (100000, 100),
        (100000, 1000),
        (100000, 10000),
        (10, 100000),
        (100, 100000),
        (1000, 100000),
        (10000, 100000),
        #(100000, 100000),
    ]

    hyperparams = [
        (1000, 10),
        (1000, 100),
        (10, 1000),
        (100, 1000),
        (1000, 1000),
    ]

    for m, shp_max in hyperparams:
        print("Generating random input with m = {m}, shp_max = {shp_max} ...")
        make_random_input(m, shp_max)

        print("Generating output ...")
        make_output()

        run_bench("reference", m, shp_max)
        run_bench("quickselect", m, shp_max)
        run_bench("quickselect_fused", m, shp_max)
        run_bench("smartselect", m, shp_max)
