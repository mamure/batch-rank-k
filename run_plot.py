import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv("benchmarks.csv")
variants = ["cub", "reference", "quickselect", "quickselect_fused", "smartselect"]
colors = dict(zip(variants, plt.rcParams["axes.prop_cycle"].by_key()["color"]))
fig, axes = plt.subplots(
    2, 2,
    figsize=(14, 10),
    sharey=True,
    sharex="col",
)

line_styles = {
    "cub": "-",
    "reference": "--",
    "quickselect": "-",
    "quickselect_fused": ":",
    "smartselect": "-.",
}
markers = {
    "cub": "o",
    "reference": "^",
    "quickselect": "s",
    "quickselect_fused": "D",
    "smartselect": "x",
}
experiments = [
    {
        "title": "Random: Number of segments = 100",
        "xlabel": "Segment size",
        "ax": axes[0, 0],
        "type": "random",
        "x": "shp_max",
    },
    {
        "title": "Random: Segment size = 100",
        "xlabel": "Number of segments",
        "ax": axes[0, 1],
        "type": "random",
        "x": "m",
    },
    {
        "title": "Adversarial: Number of segments = 100",
        "xlabel": "Segment size",
        "ax": axes[1, 0],
        "type": "adversarial",
        "x": "shp_max",
    },
    {
        "title": "Adversarial: Segment size = 100",
        "xlabel": "Number of segments",
        "ax": axes[1, 1],
        "type": "adversarial",
        "x": "m",
    },
]

x_limits = {}
for x in ["shp_max", "m"]:
    values = df.loc[df["x_var"] == x, x]
    x_limits[x] = (values.min(), values.max())

times = df["time"] / 1e6
y_limits = (times.min(), times.max())

def power_of_two_ticks(limits):
    lo, hi = limits
    min = int(np.floor(np.log2(lo)))
    max = int(np.ceil(np.log2(hi)))
    return [2**i for i in range(min, max + 1)]

x_ticks = {
    x: power_of_two_ticks(limits) for x, limits in x_limits.items()
}
y_ticks = power_of_two_ticks(y_limits)

for exp in experiments:
    ax = exp["ax"]
    subset = df[
        (df["type"] == exp["type"]) &
        (df["x_var"] == exp["x"])
    ]

    for variant in variants:
        points = subset[subset["variant"] == variant].sort_values(exp["x"])
        if points.empty:
            continue

        ax.plot(
            points[exp["x"]],
            points["time"] / 1e6,
            label=variant,
            color=colors[variant],
            linestyle=line_styles[variant],
            marker=markers[variant],
            linewidth=2,
            markersize=6,
            zorder=3,
        )

    ax.set(
        title=exp["title"],
        xlabel=exp["xlabel"],
        ylabel="Time [s]",
    )

    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_xlim(x_limits[exp["x"]])
    ax.set_ylim(y_limits)
    ax.set_xticks(x_ticks[exp["x"]])
    ax.set_yticks(y_ticks)
    ax.grid(True, which="both", linestyle="--", alpha=0.4)

handles, labels = axes[0, 0].get_legend_handles_labels()
fig.legend(
    handles,
    labels,
    loc="upper center",
    bbox_to_anchor=(0.5, 1.02),
    ncol=len(variants),
)
fig.tight_layout(rect=[0, 0, 1, 0.97])
plt.savefig("benchmark_results.png", dpi=300, bbox_inches="tight")
plt.show()
