/*
 * main.cu
 *
 *  Created on: Nov 14, 2019
 *      Author: cuda-s01
 */
#include <stdio.h>
__global__ void MatrixMulKernel(float* M, float* N, float* P, int Width) {
	// Calculate the row index of the P element and M
	int Row = blockIdx.y*blockDim.y+threadIdx.y;
	// Calculate the column index of P and N
	int Col = blockIdx.x*blockDim.x+threadIdx.x;
	if ((Row < Width) && (Col < Width)) {
		float Pvalue = 0;
		// each thread computes one element of the block sub-matrix
		for (int k = 0; k < Width; ++k) {
			Pvalue += M[Row*Width+k]*N[k*Width+Col];
		}
		P[Row*Width+Col] = Pvalue;
	}
}

int main(void)
{
	printf("Starting the program:\n");
	cudaError_t err = cudaSuccess;

	int matrix_size = 2;
    int num_of_elements = matrix_size * matrix_size;
	size_t size = num_of_elements * sizeof(float);
	printf("matrix [%d x %d] multiplication.\n", matrix_size, matrix_size);
    
    //==========================HOST===============================================

	//allocate matrixes (two input ones, one output one):
    //matrix can be represented as a flat vector in the memory - it is so in GPU, 
    //so for simplification of indexation I also use this representation on the host
	printf("Started variables allocation for the host.\n");
	float *M_h = (float *)malloc(size);
	float *N_h = (float *)malloc(size);
	float *P_h = (float *)malloc(size);

	if(M_h == NULL || N_h == NULL || P_h == NULL)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	}else printf("Allocation on host successful.\n");

	//initialize matrices:
	printf("Started initialization.\n");
	for(int i = 0; i < num_of_elements; i++)
	{
        M_h[i] = rand()/(float)RAND_MAX;
        N_h[i] = rand()/(float)RAND_MAX;
	}
	printf("Initialization fnished.\n");

    //==========================DEVICE==============================================
    
	//allocate matrixes on the device:
	printf("Started variables allocation for the device.\n");
    printf("First matrix.\n");
	float **M_d;
	err = cudaMalloc((void**)&M_d,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
    
    printf("Second matrix.\n");
	float **N_h;
	err = cudaMalloc((void**)&N_h,  size);
	if(err != cudaSuccess)
	{
		printf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
	
	printf("Third matrix.\n");
	float **P_h;
	err = cudaMalloc((void**)&P_h,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");

    
    //copy marices into the device:
    printf("Started variables copying into the device.\n");
    printf("First matrix.\n");
	err = cudaMemcpy(M_d, M_h, size, cudaMemcpyHostToDevice);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to copy first matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Copying successful.\n");
    
    printf("Second matrix.\n");
	float **N_h;
	err = cudaMemcpy(N_d, N_h, size, cudaMemcpyHostToDevice);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to copy second matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Copying successful.\n");
	
    int threadsPerBlock = 256;
    int blocksPerGrid = (num_of_elements + threadsPerBlock - 1) / threadsPerBlock;
    printf("Kernel started: %d blocks, %d threads.\n", blocksPerGrid, threadsPerBlock);
	MatrixMulKernel <<<blocksPerGrid, threadsPerBlock>>>(M_d, N_d, P_d, matrix_size);
    err = cudaGetLastError();
    
    if(err != cudaSuccess)
    {
		fprintf(stderr, "Failed to launch kernel. Error: %s.\n", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	} else printf("Kerel operations successful.\n");
    
    printf("Started variables copying from the device.\n");
    err = cudaMemcpy(P_h, P_d, size, cudaMemcpyDeviceToHost);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to copy result matrix. Error: %s.\n", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	} else printf("Copying successful.\n");
    
    //==========================TEST===============================================
    for(int i = 0; i < num_of_elements; i++)
	{
        if(fabs(M_h[i] * N_h[i] - P_h[i] > 1e-3)
        {
            fprintf(stderr, "Verification tests failed!\n");
            exit(EXIT_FAILURE);
        } 
	} 
	else printf("Test PASSED\n");

}
