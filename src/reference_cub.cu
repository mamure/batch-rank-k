#include <cuda_runtime.h>
#include <cub/device/device_segmented_radix_sort.cuh>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <numeric>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

#define CUDA_CHECK(call)                                             \
    do {                                                             \
        cudaError_t err = call;                                      \
        if (err != cudaSuccess) {                                    \
            fprintf(stderr, "CUDA error at %s:%d: %s\n",             \
                    __FILE__, __LINE__, cudaGetErrorString(err));    \
            exit(EXIT_FAILURE);                                     \
        }                                                            \
    } while (0)

template <typename T>
std::vector<T> parse_array(const std::string& line, const std::string& suffix) {
    std::vector<T> result;
    std::stringstream ss(line);

    char c;
    ss >> c; // '['

    while (ss >> std::ws && ss.peek() != ']') {
        T value;
        ss >> value;
        if (!ss) throw std::runtime_error("Invalid number");

        // Skip the type suffix (i64 or f32).
        while (ss.get(c) && c != ',' && c != ']') {}

        result.push_back(value);

        if (c == ']') break;
    }

    return result;
}

void parse_input(
    const std::string& filename,
    std::vector<int>& ks,
    std::vector<int>& shp,
    std::vector<float>& flat)
{
    std::ifstream infile(filename);
    if (!infile.is_open()) {
        throw std::runtime_error("Could not open file: " + filename);
    }

    std::string line;
    if (std::getline(infile, line)) {
        ks = parse_array<int>(line, "i64");
    }
    if (std::getline(infile, line)) {
        shp = parse_array<int>(line, "i64");
    }
    if (std::getline(infile, line)) {
        flat = parse_array<float>(line, "f32");
    }
}

void parse_output(
    const std::string& filename,
    std::vector<float>& expected)
{
    std::ifstream infile(filename);
    if (!infile.is_open()) {
        throw std::runtime_error("Could not open file: " + filename);
    }

    std::string line;
    if (std::getline(infile, line)) {
        expected = parse_array<float>(line, "f32");
    }
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

    printf("Parsing input and output datasets...\n");
    parse_input("dataset.in", h_ks, h_shp, h_flat);
    parse_output("dataset.out", h_expected);

    printf("Input sizes: ks=%zu, shp=%zu, flat=%zu, expected=%zu\n",
           h_ks.size(), h_shp.size(), h_flat.size(), h_expected.size());

    if (h_ks.empty() || h_shp.empty() || h_flat.empty() || h_expected.empty()) {
        fprintf(stderr, "Empty dataset.\n");
        return EXIT_FAILURE;
    }
    if (h_ks.size() != h_shp.size() || h_ks.size() != h_expected.size()) {
        fprintf(stderr, "Dataset sizes do not match.\n");
        return EXIT_FAILURE;
    }

    const int m = (int)h_shp.size();
    const int n = (int)h_flat.size();

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


    // Start benchmarking
    printf("Starting benchmark...\n");
    cudaEvent_t start_event;
    cudaEvent_t stop_event;
    CUDA_CHECK(cudaEventCreate(&start_event));
    CUDA_CHECK(cudaEventCreate(&stop_event));
    CUDA_CHECK(cudaEventRecord(start_event));

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
    printf("GPU time: %.4f us\n", elapsed_ms * 1000.0f);

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
