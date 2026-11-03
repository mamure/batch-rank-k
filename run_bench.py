import subprocess
import random
import time


SEED = 42
BACKEND = "cuda"
RUNS = 3
VALIDATE = False

CSV = "benchmarks.csv"
DATASET_IN = "dataset.in"
DATASET_OUT = "dataset.out"


def write_dataset(ks, shp, flat):
    with open(DATASET_IN, "w") as f:
        f.write("[" + ",".join("{}i64".format(x) for x in ks) + "]\n")
        f.write("[" + ",".join("{}i64".format(x) for x in shp) + "]\n")
        f.write("[" + ",".join("{:.2f}f32".format(x) for x in flat) + "]\n")

def make_random_input(m, shp_min, shp_max):
    shp = [
        random.randint(shp_min, shp_max)
        for _ in range(m)
    ]
    ks = [
        random.randint(1, max(shp[i], 1))
        for i in range(m)
    ]
    flat = [
        random.uniform(-1e6, 1e6)
        for _ in range(sum(shp))
    ]
    write_dataset(ks, shp, flat)

# For quickselect with the last or first element as pivot,
# sorted input gives the worst case.
def make_adversarial_input(m, shp_min, shp_max):
    shp = [
        random.randint(shp_min, shp_max)
        for _ in range(m)
    ]
    ks = [
        random.randint(1, max(shp[i], 1))
        for i in range(m)
    ]
    flat = [
        float(i)
        for i in range(sum(shp))
    ]
    write_dataset(ks, shp, flat)

def make_output():
    with open(DATASET_IN, "rb") as stdin:
        with open(DATASET_OUT, "wb") as stdout:
            subprocess.run(
                ["src/reference"],
                stdin=stdin,
                stdout=stdout,
                check=True
            )

def compile(variant):
    print("Compiling {} ...".format(variant))
    subprocess.run(
        ["futhark", BACKEND, "src/{}.fut".format(variant)],
        check=True
    )

def compile_cuda():
    print("Compiling CUDA ...")
    subprocess.run(
        ["nvcc", "-O3", "-o", "reference_cub", "src/reference_cub.cu", "-Wno-deprecated-gpu-targets"],
        check=True
    )

def run_bench(variant, args, m, shp_min, shp_max, type, x_var):
    print("\nBenchmarking {}".format(" ".join(args)))
    try:
        times = []
        for _ in range(RUNS):
            with open(DATASET_IN, "rb") as stdin:
                start = time.perf_counter()
                result = subprocess.run(
                    args,
                    stdin=stdin,
                    stdout=subprocess.PIPE,
                    check=True
                )
                end = time.perf_counter()

                if VALIDATE:
                    expected = None
                    with open(DATASET_OUT, "rb") as expected:
                        expected = expected.read()
                    if result.stdout != expected:
                        raise Exception("Incorrect output")

                times.append((end - start) * 1e6)
                print("\tTime: {:.2f} μs".format(times[-1]))

        mean = sum(times) / len(times)
        print("\tMean: {:.2f} μs".format(mean))
        with open(CSV, "a") as csv:
            csv.write("{},{},{},{},{},{},{:.2f}\n".format(
                m, shp_min, shp_max, x_var, type, variant, mean
            ))
    except Exception as e:
        print("Error occurred: {}".format(e))

def run_bench_futhark(variant, m, shp_min, shp_max, type, x_var):
    run_bench(
        variant,
        ["./src/{}".format(variant)],
        m, shp_min, shp_max, type, x_var
    )

def run_bench_cub(m, shp_min, shp_max, type, x_var):
    run_bench(
        "cub",
        ["./reference_cub"],
        m, shp_min, shp_max, type, x_var
    )


if __name__ == "__main__":
    print(f"Running benchmarks with backend {BACKEND} and seed {SEED}...")

    if BACKEND == "cuda":
        compile_cuda()
    for variant in ["reference", "smartselect", "quickselect", "quickselect_fused"]:
        compile(variant)

    with open(CSV, "w") as csv:
        csv.write("m,shp_min,shp_max,x_var,type,variant,time\n")

    fixed_value = 100
    xaxis = [1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576]

    for input_type in ["random", "adversarial"]:
        for x_var in ["m", "shp_max"]:
            random.seed(SEED) # Ensure the same datasets across different variants

            fixed = [fixed_value] * len(xaxis)
            m_values       = xaxis if x_var == "m" else fixed
            shp_max_values = fixed if x_var == "m" else xaxis
            shp_min_values = [int(1.0 * shp_max) for shp_max in shp_max_values]

            for m, shp_min, shp_max in zip(m_values, shp_min_values, shp_max_values):
                print("\nGenerating {} input with m = {}, shp_min = {}, shp_max = {} ...".format(
                    input_type, m, shp_min, shp_max
                ))
                if input_type == "random":
                    make_random_input(m, shp_min, shp_max)
                else:
                    make_adversarial_input(m, shp_min, shp_max)

                if VALIDATE:
                    print("Generating reference output ...")
                    make_output()

                if BACKEND == "cuda":
                    run_bench_cub(m, shp_min, shp_max, input_type, x_var)
                run_bench_futhark("reference", m, shp_min, shp_max, input_type, x_var)
                run_bench_futhark("smartselect", m, shp_min, shp_max, input_type, x_var)
                run_bench_futhark("quickselect", m, shp_min, shp_max, input_type, x_var)
                run_bench_futhark("quickselect_fused", m, shp_min, shp_max, input_type, x_var)
