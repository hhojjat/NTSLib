#include <assert.h>

int NonDetInt();

main(){

  int i,j, *x;

  x=(int *)malloc(100*sizeof(int));
  i = 0;
  j = NonDetInt(); 

  while(*(x+i) != 0)
    i++;

  if(j >= 0 && j < i)
    if(/* *(x+j) == 0 */ 0)
      {assert(0);}

 return (1);
}
