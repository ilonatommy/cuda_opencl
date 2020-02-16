#include <stdio.h>
// For the CUDA runtime routines (prefixed with "cuda_")
#include <cuda_runtime.h>
//#include <helper_cuda.h>
#include <time.h>
#define BLOCK_SIZE 1024
#define NUMBER_OF_ELEMENTS 1024

__global__ void vectorAdd(const float *A, const float *B, float *C, int numElements)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;

    if (i < numElements)
    {
        C[i] = A[i] + B[i];
    }
}

__global__ void total(float *input, float *output, int len) {
    //@@ Load a segment of the input vector into shared memory
    __shared__ float partialSum[2 * BLOCK_SIZE];
    unsigned int t = threadIdx.x, start = 2* blockIdx.x * BLOCK_SIZE;
    if (start + t < len)
        partialSum[t] = input[start + t];
    else
        partialSum[t] = 0;
    if (start + BLOCK_SIZE + t < len)
        partialSum[BLOCK_SIZE + t] = input[start + BLOCK_SIZE + t];
    else
        partialSum[BLOCK_SIZE + t] = 0;
    //@@ Traverse the reduction tree
    for (unsigned int stride = BLOCK_SIZE; stride >= 1; stride >>= 1) {
        __syncthreads();
        if (t < stride)
            partialSum[t] += partialSum[t + stride];
    }
    //@@ Write the computed sum of the block to the output vector at the
    //@@ correct index
    if (t == 0)
        output[blockIdx.x] = partialSum[0];
}


int main(void)
{
    // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;
    int numElements = NUMBER_OF_ELEMENTS;

    int memorySizeIn=numElements*sizeof(float);
    int memorySizeOut=sizeof(float);
    printf("Calculating the sum of %d elements.\n", numElements);
    printf("Allocating host vectors...\n");
    // Allocate the host output vector
    float *h_input = (float *)malloc(memorySizeIn);
    // Allocate the host output vector
    float *h_output = (float *)malloc(memorySizeIn);

    // Verify that allocations succeeded
    if (h_input == NULL || h_output == NULL)
    {
        fprintf(stderr, "Failed to allocate host vectors!\n");
        exit(EXIT_FAILURE);
    }
    else
        printf("Success.\n");

    // Initialize the host input vector with random values
    for (int i = 0; i < numElements; ++i)
    {
        h_input[i]=(float)rand()/(float)RAND_MAX;
        // printf("%f ", h_input[i]);
    }

    printf("Allocating device vectors... \n");
    float *d_input = NULL;
    err = cudaMallocManaged((void **)&d_input, memorySizeIn);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device input vector!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    else
        printf("Device input vector allocated.\n");

    float *d_output = NULL;
    err = cudaMallocManaged((void **)&d_output, memorySizeIn);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device output vector!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    else
        printf("Device output vector allocated.\n");

    printf("Copying input vector from the host memory to the CUDA device...\n");
    err = cudaMemcpy(d_input, h_input, memorySizeIn, cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input vector from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    else
        printf("Success.\n");

    // Launch the Kernel
    int threadsPerBlock = BLOCK_SIZE;
    int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;
    printf("CUDA kernel launching with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
    
    float sumGPU = 0;
    int k = 0;
    int iter=0;

    clock_t start=clock();

    int inputElementsLeft = numElements;
    while(inputElementsLeft > 0)
    {
        int currNumElements = inputElementsLeft;
        if(inputElementsLeft > BLOCK_SIZE*2)
            currNumElements = BLOCK_SIZE*2;

        total<<<blocksPerGrid, threadsPerBlock>>>(d_input + k, d_output, currNumElements);
        err = cudaGetLastError();
        if (err != cudaSuccess)
        {
            fprintf(stderr, "Failed to launch the kernel in %d iteration (error code %s)!\n", iter, cudaGetErrorString(err));
            exit(EXIT_FAILURE);
        }
        // Copy the device result vector in device memory to the host result vector
        // in host memory.
        err = cudaMemcpy(h_output, d_output, memorySizeOut, cudaMemcpyDeviceToHost);
        if (err != cudaSuccess)
        {
            fprintf(stderr, "Failed to copy output vector from device to host (error code %s)!\n", cudaGetErrorString(err));
            exit(EXIT_FAILURE);
        }
        float sum = h_output[0];
        sumGPU+=sum;

        k+=currNumElements;
        iter+=1;
        
        inputElementsLeft-=currNumElements;
        
    }

    cudaDeviceSynchronize();
    clock_t end=clock();

    double time_elapsed_gpu=((double) (end - start))*1000 / CLOCKS_PER_SEC;
    // Calculating the sum using CPU
    
    float sumCPU=0;
    for (int i=0; i<numElements; i++) {
        sumCPU+=h_input[i];
    }
    
    printf("GPU sum is %f and CPU sum is %f.\n", sumGPU, sumCPU);
    printf("Time elapsed for GPU computations: %lf ms.\n", time_elapsed_gpu);
    // Free device memory
    err = cudaFree(d_input);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free input vector (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    
    err = cudaFree(d_output);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free output vector (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    // Free host memory
    free(h_input);
    free(h_output);

    return 0;
}

