#include <cuda_runtime.h>
#include <cub/device/device_segmented_radix_sort.cuh>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <numeric>
#include <string>
#include <iostream>

#define CUDA_CHECK(call)                                             \
    do {                                                             \
        cudaError_t err = call;                                      \
        if (err != cudaSuccess) {                                    \
            fprintf(stderr, "CUDA error at %s:%d: %s\n",             \
                    __FILE__, __LINE__, cudaGetErrorString(err));    \
            exit(EXIT_FAILURE);                                     \
        }                                                            \
    } while (0)


void parse_input(
    const std::string& filename,
    std::vector<int>& ks,
    std::vector<int>& shp,
    std::vector<float>& flat)
{
    // TODO:
    // Parse dataset.in.
    //
    // It contains three lists:
    //   1. ks
    //   2. shp
    //   3. flat
}

void parse_output(
    const std::string& filename,
    std::vector<float>& expected)
{
    // TODO:
    // Parse dataset.out.
}

__global__ void gather_kth(
    const float* sorted,
    const int* starts,
    const int* ks,
    float* result,
    int m)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= m)
        return;
    result[i] = sorted[starts[i] + ks[i] - 1];
}

int main()
{
    std::vector<int> h_ks;
    std::vector<int> h_shp;
    std::vector<float> h_flat;
    std::vector<float> h_expected;

    parse_input("dataset.in", h_ks, h_shp, h_flat);
    parse_output("dataset.out", h_expected);

    const int m = (int)h_shp.size();
    const int n = (int)h_flat.size();

    // Start benchmarking
    cudaEvent_t start_event;
    cudaEvent_t stop_event;
    CUDA_CHECK(cudaEventCreate(&start_event));
    CUDA_CHECK(cudaEventCreate(&stop_event));
    CUDA_CHECK(cudaEventRecord(start_event));

    std::vector<int> h_starts(m);
    std::vector<int> h_ends(m);

    int offset = 0;
    for (int i = 0; i < m; ++i) {
        h_starts[i] = offset;
        offset += h_shp[i];
        h_ends[i] = offset;
    }

    int* d_ks = nullptr;
    int* d_starts = nullptr;
    int* d_ends = nullptr;

    float* d_flat_in = nullptr;
    float* d_flat_out = nullptr;
    float* d_result = nullptr;

    CUDA_CHECK(cudaMalloc((void**)&d_ks, sizeof(int) * m));
    CUDA_CHECK(cudaMalloc((void**)&d_starts, sizeof(int) * m));
    CUDA_CHECK(cudaMalloc((void**)&d_ends, sizeof(int) * m));
    CUDA_CHECK(cudaMalloc((void**)&d_flat_in, sizeof(float) * n));
    CUDA_CHECK(cudaMalloc((void**)&d_flat_out, sizeof(float) * n));
    CUDA_CHECK(cudaMalloc((void**)&d_result, sizeof(float) * m));

    CUDA_CHECK(cudaMemcpy(
        d_ks,
        h_ks.data(),
        sizeof(int) * m,
        cudaMemcpyHostToDevice));

    CUDA_CHECK(cudaMemcpy(
        d_starts,
        h_starts.data(),
        sizeof(int) * m,
        cudaMemcpyHostToDevice));

    CUDA_CHECK(cudaMemcpy(
        d_ends,
        h_ends.data(),
        sizeof(int) * m,
        cudaMemcpyHostToDevice));

    CUDA_CHECK(cudaMemcpy(
        d_flat_in,
        h_flat.data(),
        sizeof(float) * n,
        cudaMemcpyHostToDevice));

    // Allocate temporary storage for CUB.
    void* d_storage = nullptr;
    size_t storage_size = 0;

    CUDA_CHECK(cub::DeviceSegmentedRadixSort::SortKeys(
        d_storage,
        storage_size,
        d_flat_in,
        d_flat_out,
        n,
        m,
        d_starts,
        d_ends));

    CUDA_CHECK(cudaMalloc(&d_storage, storage_size));

    // Sort every segment independently.
    CUDA_CHECK(cub::DeviceSegmentedRadixSort::SortKeys(
        d_storage,
        storage_size,
        d_flat_in,
        d_flat_out,
        n,
        m,
        d_starts,
        d_ends));

    // Gather the kth rank from every segment.
    const int threads = 256;
    const int blocks = (m + threads - 1) / threads;
    gather_kth<<<blocks, threads>>>(d_flat_out, d_starts, d_ks, d_result, m);

    CUDA_CHECK(cudaGetLastError());

    // Stop benchmarking
    float elapsed_ms = 0.0f;
    CUDA_CHECK(cudaEventRecord(stop_event));
    CUDA_CHECK(cudaEventSynchronize(stop_event));
    CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms, start_event,stop_event));
    printf("GPU time: %.4f ms\n", elapsed_ms);

    // Check for correntness.
    std::vector<float> h_result(m);
    CUDA_CHECK(cudaMemcpy(
        h_result.data(),
        d_result,
        sizeof(float) * m,
        cudaMemcpyDeviceToHost));

    bool correct = true;
    for (int i = 0; i < m; ++i) {
        if (h_result[i] != h_expected[i]) {
            printf(
                "Mismatch in segment %d: expected %.9g, got %.9g\n",
                i,
                h_expected[i],
                h_result[i]);

            correct = false;
        }
    }

    printf("%s\n", correct ? "PASSED" : "FAILED");

    CUDA_CHECK(cudaEventDestroy(start_event));
    CUDA_CHECK(cudaEventDestroy(stop_event));
    CUDA_CHECK(cudaFree(d_ks));
    CUDA_CHECK(cudaFree(d_starts));
    CUDA_CHECK(cudaFree(d_ends));
    CUDA_CHECK(cudaFree(d_flat_in));
    CUDA_CHECK(cudaFree(d_flat_out));
    CUDA_CHECK(cudaFree(d_result));
    CUDA_CHECK(cudaFree(d_storage));

    return correct ? EXIT_SUCCESS : EXIT_FAILURE;
}
