#include <stdio.h> 
#include <stdlib.h>
#define N 4

void multiply(float mat1[][N], float mat2[][N], float res[][N]) 
{ 
    int i, j, k; 
    for (i = 0; i < N; i++) 
    { 
        for (j = 0; j < N; j++) 
        { 
            res[i][j] = 0; 
            for (k = 0; k < N; k++) 
                res[i][j] += mat1[i][k]*mat2[k][j]; 
        } 
    } 
} 
  
int main() 

{ 
    int c, d, j, i;
    int s=N;
    float mat1[N][N], mat2[N][N];
    for (c = 0; c < s; c++)
        for (d = 0; d < s; d++)
            mat1[c][d]=rand()/(float)RAND_MAX;
    for (c = 0; c < s; c++)
        for (d = 0; d < s; d++)
            mat2[c][d]=rand()/(float)RAND_MAX;
    printf("First matrix is \n"); 
    for (i = 0; i < N; i++) 
    { 
        for (j = 0; j < N; j++) 
           printf("%f ", mat1[i][j]); 
        printf("\n"); 
    }

    printf("Second matrix is \n"); 
    for (i = 0; i < N; i++) 
    { 
        for (j = 0; j < N; j++) 
           printf("%f ", mat2[i][j]); 
        printf("\n"); 
    }

    float res[N][N]; // To store result 
    // int i, j; 
    multiply(mat1, mat2, res); 
  
    printf("Result matrix is \n"); 
    for (i = 0; i < N; i++) 
    { 
        for (j = 0; j < N; j++) 
           printf("%f ", res[i][j]); 
        printf("\n"); 
    } 
  
    return 0; 
} 