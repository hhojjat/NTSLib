#include <assert.h>
//int __BLAST_NONDET;
int NonDetInt();

main(){

  int i,j, x[100];

  i = 0;
  j = NonDetInt();

  while(x[i] != 0)
    i++;

  if(j >= 0 && j < i)
    if(  i<0)
      {
	assert(0);
	}
}
