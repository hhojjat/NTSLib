#include <assert.h>
int NonDetInt();

main(){
  
  char x[100], y[100];
  int i,j,k;
  
  k = NonDetInt();
  
  i = 0;
  while(x[i] != 0){
    y[i] = x[i];
    i++;
  }
  y[i] = 0;
  
  if(k >= 0 && k < i)
    if( k-i > 0)
      {assert(0);}
}
