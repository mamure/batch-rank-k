# batch-rank-k

Flattened implementation of a **batch rank-search-k** algorithm (selection by rank) for the PMPH course project.  
We present a baseline reference implementation that uses radix sort on each segment, then chooses the kth element.  
We also provide a flattened and optimized quickselect implementation as well as a "smartselect" implementation, which is quickselect with smart pivot selection that ensures O(n) runtime.

## Setup
We use the radix sort implementation from `github.com/diku-dk/sorts` as our reference.  
This needs to be downloaded and synced via the following two commands:  

`futhark pkg add github.com/diku-dk/sorts`  
`futhark pkg sync`  

## How to run tests
`futhark test tests/main.fut`

## How to run benchmarks
TODO
