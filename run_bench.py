import subprocess
import random
import re
import statistics
import math


SEED = 42
BACKEND = "cuda"
CSV = "benchmarks.csv"
DATASET_IN = "dataset.in"
DATASET_OUT = "dataset.out"


def write_dataset(ks, shp, flat):
    with open(DATASET_IN, "w") as f:
        f.write("[" + ",".join("{}i64".format(x) for x in ks) + "]\n")
        f.write("[" + ",".join("{}i64".format(x) for x in shp) + "]\n")
        f.write("[" + ",".join("{:.2f}f32".format(x) for x in flat) + "]\n")


def make_random_input(m, shp_max):
    shp = [
        random.randint(1, shp_max)
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
def make_adversarial_input(m, shp_max):
    shp = [
        random.randint(1, shp_max)
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
    subprocess.run(
        ["futhark", BACKEND, "src/reference.fut"],
        check=True
    )

    with open(DATASET_IN, "rb") as stdin:
        with open(DATASET_OUT, "wb") as stdout:
            subprocess.run(
                ["src/reference"],
                stdin=stdin,
                stdout=stdout,
                check=True
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

    raise ValueError("Failed to parse benchmark output.")

def run_bench(variant, m, shape_max, type, x_var):
    print("\nBenchmarking {} ...".format(variant))
    result = subprocess.run(
        ["futhark", "bench", "bench/{}.fut".format(variant)],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )
    time, ci_lo, ci_hi = parse_output(result.stdout)

    print("Time: {:.2f} μs (95% CI: [{:.2f}, {:.2f}])".format(time, ci_lo, ci_hi))
    with open(CSV, "a") as csv:
        csv.write("{},{},{},{},{},{:.2f},{:.2f},{:.2f}\n".format(
            m, shape_max, x_var, type, variant, time, ci_lo, ci_hi
        ))


def parse_output_cub(stdout):
    pat = re.compile(r"^GPU time:\s+([+-]?(?:[0-9]*[.])?[0-9]+)\s+us")
    for line in stdout.splitlines():
        match = pat.match(line)
        if match:
            time = float(match.group(1))
            return time

    raise ValueError("Failed to parse CUDA benchmark output.")

def run_bench_cub(m, shape_max, type, x_var):
    print("\nBenchmarking CUDA CUB ...")
    times = []
    for _ in range(10):
        result = subprocess.run(
            ["./reference_cub"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        times.append(parse_output_cub(result.stdout))
        print("Time: {:.2f} μs".format(times[-1]))

    mean = statistics.mean(times)
    std = statistics.stdev(times)
    margin = 2.262 * std / math.sqrt(len(times))
    lower = mean - margin
    upper = mean + margin

    print("Time: {:.2f} μs (95% CI: [{:.2f}, {:.2f}])".format(mean, lower, upper))
    with open(CSV, "a") as csv:
        csv.write("{},{},{},{},{},{:.2f},{:.2f},{:.2f}\n".format(
            m, shape_max, x_var, type, "cub", mean, lower, upper
        ))


if __name__ == "__main__":
    random.seed(SEED)

    subprocess.run(
        ["nvcc", "-O3", "-o", "reference_cub", "src/reference_cub.cu"],
        check=True
    )

    with open(CSV, "w") as csv:
        csv.write("m,shape_max,x_var,type,variant,time,ci_lo,ci_hi\n")

    fixed_value = 1000
    xaxis = [100 * 2**i for i in range(int(math.log2(10000 // 100) + 2))]

    for input_type in ["random", "adversarial"]:
        for x_var in ["m", "shape_max"]:
            fixed = [fixed_value] * len(xaxis)
            m_values       = xaxis if x_var == "m" else fixed
            shp_max_values = fixed if x_var == "m" else xaxis
            for m, shp_max in zip(m_values, shp_max_values):
                try:
                    print("Generating {} input with m = {}, shp_max = {} ...".format(
                        input_type, m, shp_max
                    ))
                    if input_type == "random":
                        make_random_input(m, shp_max)
                    else:
                        make_adversarial_input(m, shp_max)

                    print("Generating output ...")
                    make_output()

                    run_bench_cub(m, shp_max, input_type, x_var)
                    run_bench("reference", m, shp_max, input_type, x_var)
                    run_bench("smartselect", m, shp_max, input_type, x_var)
                    run_bench("quickselect", m, shp_max, input_type, x_var)
                    run_bench("quickselect_fused", m, shp_max, input_type, x_var)
                except Exception as e:
                    print("Error occurred: {}".format(e))
                    continue
