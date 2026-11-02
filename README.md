# batch-rank-k

Flattened implementation of a **batch rank-search-k** algorithm (batched selection by rank) for the PMPH course project.  

We present 5 variants:
- A naive CUDA CUB implementation, `cub`, that uses `DeviceSegmentedRadixSort` to sort each segment, then selects the kth element from each segment.
- A naive futhark implementation, `reference`, that uses a radix sort from `github.com/diku-dk/sorts` to sort each segment, then selects the kth element from each segment.
- A quickselect implementation, `quickselect`, that uses last element in each segment as pivot. Based on the derivation in the report.
- A quickselect implementation, `quickselect_fused` that has manually fused some `map` operations from the `quickselect` partition scheme.
- A smartselect implementation, `smartselect` that uses the `quickselect_fused` partition scheme, but with a median-of-medians pivot selection strategy. It does not use the exact BFPRT algorithm, rather an approximation. It offers better performance for adversarial inputs compared to `quickselect` and `quickselect_fused`, but does not guarantee O(n).

## How to run
Use either of the following to run the tests or benchmarks respectively.  
`python3 run_tests.py`  
`python3 run_bench.py`  

To analyze and plot the benchmark results, use:  
`python3 run_plot.py`  