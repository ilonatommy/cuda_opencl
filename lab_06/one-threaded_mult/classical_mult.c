#include <stdio.h>
#include <stdlib.h>
 
int main()
{
  int s, c, d, k, sum = 0;
  
 
  printf("Enter the size:\n");
  scanf("%d", &s);
  float first[s][s], second[s][s], multiply[s][s];
 
  printf("Initializing matrices...");
  for (c = 0; c < s; c++)
    for (d = 0; d < s; d++)
      first[c][d]=rand()/(float)RAND_MAX;
      second[c][d]=rand()/(float)RAND_MAX;
  printf("Initialization successfull. Multiplying...\n");
 
    for (c = 0; c < s; c++) {
      for (d = 0; d < s; d++) {
        for (k = 0; k < s; k++) {
          sum = sum + first[c][k]*second[k][d];
        }
 
        multiply[c][d] = sum;
        sum = 0;
      }
    }
 
    printf("Product of the matrices:\n");
 
    for (c = 0; c < s; c++) {
      for (d = 0; d < s; d++)
        printf("%f\t", multiply[c][d]);
 
      printf("\n");
    }
  
 
  return 0;
}