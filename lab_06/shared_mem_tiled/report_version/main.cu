
/*
 * main.cu
 *
 *  Created on: Nov 14, 2019
 *  Author: cuda-s01
 */
#include <stdio.h>
#include <time.h>

const int TILE_WIDTH = 2;
const int MATRIX_SIZE =8;


__global__ void matrixMultiplicationKernel(float* M, float* N, float* P, int Width) {
        // Calculate the row index of the P element and M
        int Row = blockIdx.y*blockDim.y+threadIdx.y;
        // Calculate the column index of P and N
        int Col = blockIdx.x*blockDim.x+threadIdx.x;

        __shared__ float sum_M[TILE_WIDTH][TILE_WIDTH];
        __shared__ float sum_N[TILE_WIDTH][TILE_WIDTH];

        sum_M[threadIdx.y][threadIdx.x]=0.0;
        sum_N[threadIdx.y][threadIdx.x]=0.0;

        float Pval = 0;
        for(int k=0; k<((Width - 1)/TILE_WIDTH + 1); k++)
        {
                //printf("Col:%d, Row:%d, k:%d, th:(%d,%d), ");
                if(k*TILE_WIDTH + threadIdx.x < Width && Row < Width)
                        sum_M[threadIdx.y][threadIdx.x] = M[Row*Width + k*TILE_WIDTH + threadIdx.x];
                else sum_M[threadIdx.y][threadIdx.x] = 0.0;

                if(k*TILE_WIDTH + threadIdx.y < Width && Col < Width)
                        sum_N[threadIdx.y][threadIdx.x] = N[(k*TILE_WIDTH + threadIdx.y)*Width + Col];
                else sum_N[threadIdx.y][threadIdx.x] = 0.0;

                __syncthreads();

                for(int n=0; n<TILE_WIDTH;++n)
                        Pval += sum_M[threadIdx.y][n] * sum_N[n][threadIdx.x];

                __syncthreads();

        }
    if(Row < Width && Col < Width)
        {
                P[Row * Width + Col]  = Pval;
                //printf("(%d,%d)=%f\n",Row,Col,P[Row*Width+Col]);
        }


}

void multiply(float* M, float* N, float* P, int size) {
    float X[size][size], Y[size][size], Z[size][size];
    int i, j;

    printf("Rewriting matrices\n");
    for (i=0;i<size;i++) {
        for (j=0;j<size;j++) {
            X[i][j]=M[size*i+j];
            Y[i][j]=N[size*i+j];
            Z[i][j]=0;
        }
    }

    // Multiplying first and second matrices and storing in Z.
    for (i = 0; i < size; ++i) {
        for (j = 0; j < size; ++j) {
            for (int k = 0; k < size; ++k) {
                Z[i][j] += X[i][k] * Y[k][j];
            }
    }
    }
    printf("Result matrix:\n");
    for (i=0;i<size;i++) {
        for (j=0;j<size;j++) {
            P[size*i+j]=Z[i][j];
        }
    printf("\n");
    }


}

void matrixMultiplication(float *M, float *N, float *P, int Width){

    // declare the number of blocks per grid and the number of threads per block
    int th = TILE_WIDTH;
    int bl = (Width/TILE_WIDTH) + 1;
    dim3 threadsPerBlock(th,th,1);
    dim3 blocksPerGrid(bl,bl,1);
    printf("Kernel started: (%d,%d,1) grid, (%d,%d,1) blocks.\n", bl,bl, th,th);
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

void matrixSingleMultiplication(float *M, float *N, float *P) {
        printf("Single threaded multiplication happening\n");
        PrintMatrix(M, MATRIX_SIZE);

}


int main(void)
{
        printf("Starting the program:\n");
        cudaError_t err = cudaSuccess;

        int matrix_size = MATRIX_SIZE;
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
    clock_t start=clock();
    matrixMultiplication(M, N, P, matrix_size);
    clock_t end=clock();
    double time_elapsed=((double) (end - start)) / CLOCKS_PER_SEC;
    err = cudaGetLastError();

    if(err != cudaSuccess)
    {
                fprintf(stderr, "Failed to launch kernel. Error: %s.\n", cudaGetErrorString(err));
                exit(EXIT_FAILURE);
        } else printf("Kernel operations successful. Time elapsed: %lf s.\n", time_elapsed);



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
                        //debug line:
                        //printf("%f ",tmp);
                        if(fabs(tmp - P[i*matrix_size + j]) > 1e-3)
                        {
                                fprintf(stderr, "Verification test failed.!\nElement at index (%d, %d) should be %f, but is %f. \n",
                                        i,j,tmp,P[i*matrix_size + j]);
                                exit(EXIT_FAILURE);
                        }
                }
        }

        printf("Test PASSED\n");

    //============================ Single-threaded approach ==========================

        multiply(M, N, P, MATRIX_SIZE);
        PrintMatrix(P, matrix_size);
        printf("Now freeing memory.\n");

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
