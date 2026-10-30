import subprocess
import random
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# TODO create a benchmarking framework that runs the different implementation
# for increasing dataset sizes.
# Then does some simple matplotlib yada yada to plot the results.

# TODO somehow generate non degenerate datasets for the benchmark.
def run_metadata(num_runs):
    metadata = []
    for i in range(num_runs):
        metadata.append({
            "seed": random.randint(0, 2**32 - 1),
            "n": (0, 100 * 10 ** num_runs),
            "m": (0, 100 * 10 ** num_runs),
        })
    return metadata

subprocess.run(["futhark-dataset", "-b", "-s", str(seed), "-g"])
