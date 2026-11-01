import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("benchmarks.csv")

variants = ["cub", "reference", "quickselect", "quickselect_fused", "smartselect"]
types = ["random", "adversarial"]
colors = dict(zip(variants, plt.rcParams["axes.prop_cycle"].by_key()["color"]))
fig, axes = plt.subplots(2, 2, figsize=(14, 10))

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
        "title": "Random: Number of segments = 1000",
        "xlabel": "Max segment size",
        "ax": axes[0, 0],
        "type": "random",
        "x": "shape_max",
    },
    {
        "title": "Random: Max segment size = 1000",
        "xlabel": "Number of segments",
        "ax": axes[0, 1],
        "type": "random",
        "x": "m",
    },
    {
        "title": "Adversarial: Number of segments = 1000",
        "xlabel": "Max segment size",
        "ax": axes[1, 0],
        "type": "adversarial",
        "x": "shape_max",
    },
    {
        "title": "Adversarial: Max segment size = 1000",
        "xlabel": "Number of segments",
        "ax": axes[1, 1],
        "type": "adversarial",
        "x": "m",
    },
]

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
            points["time"],
            label=variant,
            color=colors[variant],
            linestyle=line_styles.get(variant, "-"),
            marker=markers.get(variant, "o"),
            linewidth=2,
            markersize=6,
            zorder=3,
        )
        ax.fill_between(
            points[exp["x"]],
            points["ci_lo"],
            points["ci_hi"],
            color=colors[variant],
            alpha=0.15,
        )

    ax.set(
        title=exp["title"],
        xlabel=exp["xlabel"],
        ylabel="Execution time (µs)",
    )
    ax.set_yscale("log", base=10)
    ax.set_xscale("log", base=2)

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
