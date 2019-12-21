__global__
void deviceKernel(int *a, int N)
{
  int idx = threadIdx.x + blockIdx.x * blockDim.x;
  int stride = blockDim.x * gridDim.x;

  for (int i = idx; i < N; i += stride)
  {
    a[i] = 1;
  }
}

//function to compare and check results
void hostFunction(int *a, int N)
{
  for (int i = 0; i < N; ++i)
  {
    a[i] = 1;
  }
}

int main()
{

  int N = 2<<24;
  size_t size = N * sizeof(int);
  int *a;
  cudaMallocManaged(&a, size);
  
  // What happens when unified memory is accessed only by the GPU?
  int threadsPerBlock = 32 << 2; //max: 1024
  int blocksPerGrid = 32;
  
  int choice = 4;
  if(choice == 1)
  {
   //print("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
   deviceKernel<<<blocksPerGrid, threadsPerBlock>>>(a, N);
  }
  if(choice == 2){
   hostFunction(a, N);
  } 
  if(choice == 3){
   deviceKernel<<<blocksPerGrid, threadsPerBlock>>>(a, N);
   hostFunction(a, N); 
  }
  if(choice == 4){
   hostFunction(a, N);
   deviceKernel<<<blocksPerGrid, threadsPerBlock>>>(a, N);
  }

  /*
   * Conduct experiments to learn more about the behavior of
   * `cudaMallocManaged`.
   *
   * What happens when unified memory is accessed only by the GPU?
   * What happens when unified memory is accessed only by the CPU?
   * What happens when unified memory is accessed first by the GPU then the CPU?
   * What happens when unified memory is accessed first by the CPU then the GPU?
   *
   * Hypothesize about UM behavior, page faulting specificially, before each
   * experiement, and then verify by running `nvprof`.
   */

  cudaFree(a);
}

