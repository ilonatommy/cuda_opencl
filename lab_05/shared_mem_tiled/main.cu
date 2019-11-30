
/*
 * main.cu
 *
 *  Created on: Nov 14, 2019
 *      Author: cuda-s01
 */
#include <stdio.h>
__global__ void matrixMultiplicationKernel(float* M, float* N, float* P, int Width) {
	// Calculate the row index of the P element and M
	int Row = blockIdx.y*blockDim.y+threadIdx.y;
	// Calculate the column index of P and N
	int Col = blockIdx.x*blockDim.x+threadIdx.x;
	const int tile_width = 2;
	__shared__ float sum_M[tile_width][tile_width];
	__shared__ float sum_N[tile_width][tile_width];

	float Pval = 0;

	for(int k=0; k<(tile_width + Width + 1)/tile_width; k++)
	{
		if(k*tile_width + threadIdx.x < Width && Row < Width)
			sum_M[threadIdx.y][threadIdx.x] = M[Row*Width + k*tile_width + threadIdx.x];
		else sum_M[threadIdx.y][threadIdx.x] = 0.0;
		
		if(k*tile_width + threadIdx.y < Width && Col < Width)
			sum_N[threadIdx.y][threadIdx.x] = N[(k*tile_width + threadIdx.y)*Width + Col];
		else sum_M[threadIdx.y][threadIdx.x] = 0.0;

		__syncthreads();

		for(int n=0; n<tile_width;n++)
			Pval += sum_M[threadIdx.y][n] * sum_N[n][threadIdx.x];

		__syncthreads();

	}
	if(Row < Width && Col < Width)
		P[((blockIdx.y * blockDim.y + threadIdx.y) * Width) +
		(blockIdx.x * blockDim.x) + threadIdx.x] = Pval;

}

void matrixMultiplication(float *M, float *N, float *P, int Width){

    // declare the number of blocks per grid and the number of threads per block
    int threadsPerBlock = Width*Width;
    int blocksPerGrid = Width*Width;
    printf("Kernel started: %d blocks, %d threads.\n", blocksPerGrid, threadsPerBlock);
    matrixMultiplicationKernel<<<blocksPerGrid,threadsPerBlock>>>(M, N, P, Width);
}

void PrintMatrix(float* M, int Width)
{
	for(int i = 0; i < Width; i++)
	{
		for(int j = 0; j < Width; j++)
			printf("%f  ",M[i*Width+j]);
		printf("\n");
	}
	printf("\n");
}

int main(void)
{
	printf("Starting the program:\n");
	cudaError_t err = cudaSuccess;

	int matrix_size = 4;
    	int num_of_elements = matrix_size * matrix_size;
	size_t size = num_of_elements * sizeof(float);
	printf("matrix [%d x %d] multiplication.\n", matrix_size, matrix_size);
    
    //==========================Shared Memory============================================
    
	//allocate matrixes on the device:
	printf("Started variables allocation for the device.\n");
    printf("First matrix.\n");
	float *M;
	err = cudaMallocManaged((void**)&M,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate M matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
    
    printf("Second matrix.\n");
	float *N;
	err = cudaMallocManaged((void**)&N,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate N matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
	
	printf("Third matrix.\n");
	float *P;
	err = cudaMallocManaged((void**)&P,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate P matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");

	//initialisation:
	for(int i=0; i<num_of_elements; i++)
	{
	  M[i] = rand()/(float)RAND_MAX;
	  N[i] = rand()/(float)RAND_MAX;
	}
	printf("Initialisation finished.\n");
    
    //calculations:
    matrixMultiplication(M, N, P, matrix_size);
    err = cudaGetLastError();
    
    if(err != cudaSuccess)
    {
		fprintf(stderr, "Failed to launch kernel. Error: %s.\n", cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	} else printf("Kerel operations successful.\n");
    
    
    //==========================TEST===============================================
	PrintMatrix(M, matrix_size);
	PrintMatrix(N, matrix_size);
	PrintMatrix(P, matrix_size);	

	for(int i = 0; i < matrix_size; i++)
	{
		for(int j = 0; j < matrix_size; j++)
		{
			float tmp = 0;
			for(int k = 0; k < matrix_size; k++)
				tmp += M[i*matrix_size + k] * N[k*matrix_size + j];
			printf("%f ",tmp);
			if(fabs(tmp - P[i*matrix_size + j] > 1e-3))
			{
				fprintf(stderr, "Verification test failed.!\nElement at index (%d, %d) should be %f, but is %f. \n",
					i,j,tmp,P[i*matrix_size + j]);
				exit(EXIT_FAILURE);
			}
		}
    	}

	printf("Test PASSED\n");
    
    // Free device global memory
    err = cudaFree(M);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix M (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(N);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix N (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(P);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix P (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    
    printf("Done\n");
    return 0;    
	
}

