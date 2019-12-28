#include <stdio.h> 
#include <stdlib.h>
#define S 2

void PrintMatrix(int* M, int Width)
{
        for(int i = 0; i < Width; i++)
        {
                for(int j = 0; j < Width; j++)
                        printf("%d  ",M[i*Width+j]);
                printf("\n");
        }
    printf("\n");
}

void multiply(int* M, int* N, int* P, int size) {
    int X[size][size], Y[size][size], Z[size][size];
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

int main() {
    int* M=malloc(S*S*sizeof(int)); // pierwsza macierz
    int* N=malloc(S*S*sizeof(int)); // druga macierz
    int* P=malloc(S*S*sizeof(int)); // macierz wynikowa


    int i, j;
    for (i=0;i<S;i++) {
        for (j=0;j<S;j++) {
            M[i*S+j]=rand()%10   ;     
        }
    }

    for (i=0;i<S;i++) {
        for (j=0;j<S;j++) {
            N[i*S+j]=rand()%10;
            P[i*S+j]=0;
        }
    }
    


    PrintMatrix(M, S);
    PrintMatrix(N, S);
    PrintMatrix(P, S);

    multiply(M, N, P, S);
    PrintMatrix(P, S);

    return 0;
}