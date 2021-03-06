/*
 * main.cu
 *
 *  Created on: Nov 14, 2019
 *      Author: cuda-s01
 */

const int WIDTH = 10;

#include <stdio.h>
__global__ void matrixMultiplicationKernel(float* M, float* N, float* P) {
    // Calculate the row index of the P element and M
    int Row = blockIdx.y*blockDim.y+threadIdx.y;
    // Calculate the column index of P and N
    int Col = blockIdx.x*blockDim.x+threadIdx.x;
    
    __shared__ float s_M[WIDTH * WIDTH];
    __shared__ float s_N[WIDTH * WIDTH];
 
	//debug line:
	//printf("Row:%d, Col:%d. BlockIdx(%d,%d), blockDim(%d,%d) threadIdx(%d,%d)\n\n",Row,Col,blockIdx.x,blockIdx.y,blockDim.x,blockDim.y,threadIdx.x,threadIdx.y);
     if ((Row < WIDTH) && (Col < WIDTH)) {
         float Pvalue = 0;
         
         s_M[Row*WIDTH + Col] = M[Row*WIDTH + Col];
         s_N[Row*WIDTH + Col] = N[Row*WIDTH + Col];
         __syncthreads();

	 // each thread computes one element of the block sub-matrix
	 for (int k = 0; k < WIDTH; ++k) {
	    Pvalue += s_M[Row*WIDTH+k]*s_N[k*WIDTH+Col];
	}
	P[Row*WIDTH+Col] = Pvalue;
      }
      else P[Row*WIDTH+Col] =  99.9;
}

void matrixMultiplication(float *M, float *N, float *P){

    // declare the number of blocks per grid and the number of threads per block
    int th = WIDTH;
    int bl = 1;
    dim3 threadsPerBlock(th,th);
    dim3 blocksPerGrid(bl,bl);
    printf("Kernel started: %d blocks, %d threads.\n", bl, th);
    matrixMultiplicationKernel<<<blocksPerGrid,threadsPerBlock>>>(M, N, P);
}

void PrintMatrix(float* M)
{
	for(int i = 0; i < WIDTH; i++)
	{
		for(int j = 0; j < WIDTH; j++)
			printf("%f  ",M[i*WIDTH+j]);
		printf("\n");
	}
	printf("\n");
}

int main(void)
{
	printf("Starting the program:\n");
	cudaError_t err = cudaSuccess;

	int matrix_size = WIDTH;
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
	float *M_d;
	err = cudaMalloc((void**)&M_d,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
    
    printf("Second matrix.\n");
	float *N_d;
	err = cudaMalloc((void**)&N_d,  size);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to allocate host matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Allocation successful.\n");
	
	printf("Third matrix.\n");
	float *P_d;
	err = cudaMalloc((void**)&P_d,  size);
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
	err = cudaMemcpy(N_d, N_h, size, cudaMemcpyHostToDevice);
	if(err != cudaSuccess)
	{
		fprintf(stderr, "Failed to copy second matrix!\n");
		exit(EXIT_FAILURE);
	} else printf("Copying successful.\n");
	
    //calculations:
    matrixMultiplication(M_d, N_d, P_d);
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
	PrintMatrix(M_h);
	PrintMatrix(N_h);
	PrintMatrix(P_h);	

	for(int i = 0; i < matrix_size; i++)
	{
		for(int j = 0; j < matrix_size; j++)
		{
			float tmp = 0;
			for(int k = 0; k < matrix_size; k++)
				tmp += M_h[i*matrix_size + k] * N_h[k*matrix_size + j];
			//debug line:
			//printf("%f ",tmp);
			if(fabs(tmp - P_h[i*matrix_size + j]) > 1e-3)
			{
				fprintf(stderr, "Verification test failed.!\nElement at index (%d, %d) should be %f, but is %f. \n",
					i,j,tmp,P_h[i*matrix_size + j]);
				exit(EXIT_FAILURE);
			}
		}
    	}

	printf("Test PASSED\n");
    
    // Free device global memory
    err = cudaFree(M_d);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix M (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(N_d);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix N (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaFree(P_d);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to free device matrix P (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    
    // Free host memory
    free(M_h);
    free(N_h);
    free(P_h);
    
    printf("Done\n");
    return 0;    
	
}

