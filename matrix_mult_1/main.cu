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
	printf("Entering the program.\n");
	cudaError_t err = cudaSuccess;

	int matrix_size = 2;
	size_t size = matrix_size * matrix_size * sizeof(float);
	printf("Matrix [%d %d] multiplication.", matrix_size, matrix_size);

	//allocate matrixes (two input ones, one output one):
	printf("Started variables allocation for the host.");
	float **M_h = (float **)malloc(rows * sizeof(float*));
	float **N_h = (float **)malloc(rows * sizeof(float*));
	float **P_h = (float **)malloc(rows * sizeof(float*));

	if(M_h == NULL || N_h == NULL || P_h == NULL)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	}

	for(int i = 0; i < matrix_size; i++)
	{
		M_h[i] = (float *)malloc(matrix_size * sizeof(float));
		if(M_h[i] == NULL)
		{
			printf(stderr, "Failed to allocate host matrix!\n");
			exit(EXIT_FAILURE);
		}
	}
	for(int i = 0; i < matrix_size; i++)
	{
		N_h[i] = (float *)malloc(matrix_size * sizeof(float));
		if(N_h[i] == NULL)
		{
			printf(stderr, "Failed to allocate host matrix!\n");
			exit(EXIT_FAILURE);
		}
	}
	for(int i = 0; i < matrix_size; i++)
	{
		P_h[i] = (float *)malloc(matrix_size * sizeof(float));
		if(P_h[i] == NULL)
		{
			printf(stderr, "Failed to allocate host matrix!\n");
			exit(EXIT_FAILURE);
		}
	}

	//initialize matrices:
	printf("Started initialization.");
	for(int i = 0; i <matrix_size; i++)
	{

	}

	//allocate matrixes on the device:
	printf("Started variables allocation for the device.");
	float **M_d;
	err = cudaMalloc((void**)&M_d,  matrix_size * matrix_size * sizeof(float*));
	if(err != cudaSuccess)
	{
		printf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	}

	float **N_h;
	err = cudaMalloc((void**)&N_h,  matrix_size * matrix_size * sizeof(float*));
	if(err != cudaSuccess)
	{
		printf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	}
	float **P_h;
	err = cudaMalloc((void**)&P_h,  matrix_size * matrix_size * sizeof(float*));
	if(err != cudaSuccess)
	{
		printf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	}

	//MatrixMulKernel <<<1, 5>>>();

}
