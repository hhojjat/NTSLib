#include <assert.h>
#include <assert.h>
int NonDetInt();


main(){
  
  char x[101], y[101], z[201];
  int from,to,i,j,k;
  
  from = NonDetInt(); 
  to = NonDetInt();
  k = NonDetInt();

  if(!(k >=0 && k <= 100 ))  /* assume strlen(x) <= 100 */
    assert(0);	

  if(!(from >= 0 && from <= k))            /* assume "from" index is O.K. */
    assert(1);
  
  /* extract substring form index "from" to index "to" */

  i = from;
  j = 0;
  while(x[i] != 0 && i < to){
    z[j] = x[i];
    i++;
    j++;
  }
  
  z[j] = 0;
  
  if(!(j-j <= 100))
    assert(0);  
}
