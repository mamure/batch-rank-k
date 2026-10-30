# batch-rank-k

Flattened implementation of a **batch rank-search-k** algorithm (selection by rank) for the PMPH course project.  
We present a baseline reference implementation that uses radix sort on each segment, then chooses the kth element.  
We also provide a flattened and optimized quickselect implementation as well as a "smartselect" implementation, which is quickselect with smart pivot selection that ensures O(n) runtime.

## How to run
Use either of the following to run the tests or benchmarks respectively.  
`python run_tests.py`  
`python run_bench.py`
