#include <assert.h>

int NonDetInt();
 

main(){
  
  char x[101], y[101], z[201];
  int i,j,k;
  
  i = 0;
  while(x[i] != 0){
    z[i] = x[i];
    i++;
  }

  if(i >= 100)
    {
    assert(0);
   } 


	/* assume strlen(x) < 100 */

  j = 0;
  while(y[j] != 0){
    z[i] = y[j];
    i++;
    j++;
  }

  if(j >= 100)
    assert(0); /* assume strlen(y) < 100 */

  z[j] = 0;
  
  if(i >= 200)
    assert(0); /* prove we don't overflow z */
}
