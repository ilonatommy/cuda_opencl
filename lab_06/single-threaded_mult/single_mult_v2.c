#include <stdio.h> 
#include <stdlib.h>
#define S 3

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

void multiply(float* M, float* N, float* P, int size) {
    

}

int main() {
    float* M=malloc(S*S*sizeof(float)); // pierwsza macierz
    float* N=malloc(S*S*sizeof(float)); // druga macierz
    float* P=malloc(S*S*sizeof(float)); // macierz wynikowa

    int i, j;
    printf("Filling matrix M\n");
    for (i=0;i<S;i++) {
        for (j=0;j<S;j++) {
            M[i*S+j]=(float)rand()/(float)RAND_MAX;         
        }
    }

    for (i=0;i<S;i++) {
        for (j=0;j<S;j++) {
            N[i*S+j]=(float)rand()/(float)RAND_MAX;
        }
    }


    PrintMatrix(M, S);
    PrintMatrix(N, S);

    multiply(M, N, P, S);
    PrintMatrix(P, S);

    return 0;
}