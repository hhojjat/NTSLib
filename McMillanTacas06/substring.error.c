#include <assert.h>
int NonDetInt();
main(){
  
  char x[101], y[101], z[201];
  int from,to,i,j,k;
  
  from = NonDetInt();
  to = NonDetInt();
  k = NonDetInt();

  i = from;
  j = 0;
  while(x[i] != 0 && i < to){
    z[j] = x[i];
    i++;
    j++;
  }
  
  if(k >= 0 && k < j)
    if(/* z[k] == 0 */ 0)
      {assert(0);}  /* prove strlen(z) == j */
	
return (1);	
}
