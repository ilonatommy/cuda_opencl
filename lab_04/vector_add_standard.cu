#include <stdio.h>

void initWith(float num, float *a, int N)
{
  for(int i = 0; i < N; ++i)
  {
    a[i] = num;
  }
}

__global__
void addVectorsInto(float *result, float *a, float *b, int N)
{
  int index = threadIdx.x + blockIdx.x * blockDim.x;
  int stride = blockDim.x * gridDim.x;

  for(int i = index; i < N; i += stride)
  {
    result[i] = a[i] + b[i];
  }
}

void checkElementsAre(float target, float *vector, int N)
{
  for(int i = 0; i < N; i++)
  {
    if(vector[i] != target)
    {
      printf("FAIL: vector[%d] - %0.0f does not equal %0.0f\n", i, vector[i], target);
      exit(1);
    }
  }
  //printf("Success! All values calculated correctly.\n");
}

int main()
{
  int deviceId;
  int numberOfSMs;

  cudaGetDevice(&deviceId);
  cudaDeviceGetAttribute(&numberOfSMs, cudaDevAttrMultiProcessorCount, deviceId);
  
  printf("Running the standard vector add using managed memory with %d streaming multiprocessors.",numberOfSMs );
  const long long int N = 2<<31;
  size_t size = N * sizeof(float);

  float *a;
  float *b;
  float *c;

  cudaMallocManaged(&a, size);
  cudaMallocManaged(&b, size);
  cudaMallocManaged(&c, size);

  size_t threadsPerBlock;
  size_t numberOfBlocks;

  threadsPerBlock = 256;
  numberOfBlocks = 32 * numberOfSMs;
  printf("Grid layout: %d threads per block, %d blocks per grid.", threadsPerBlock, numberOfBlocks);

  cudaError_t addVectorsErr;
  cudaError_t asyncErr;
  for(int i=0; i < 5; i++)
  {
     initWith(3, a, N);
     initWith(4, b, N);
     initWith(0, c, N);

     addVectorsInto<<<numberOfBlocks, threadsPerBlock>>>(c, a, b, N);
  
     addVectorsErr = cudaGetLastError();
     if(addVectorsErr != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(addVectorsErr));

     asyncErr = cudaDeviceSynchronize();
     if(asyncErr != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(asyncErr));

     checkElementsAre(7, c, N);
  }
  cudaFree(a);
  cudaFree(b);
  cudaFree(c);
}

