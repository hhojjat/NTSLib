// This gives a bogus counterexample as we don't encode:
// i=j -> a[i] = a[j] 
// need to generalize the boolean closure operation of the POPL04 paper

#include <assert.h>


int skip;
int x[10], y[10];
int i,j,n;

int main(){
    for(i = 0; i < n; i++){
      y[i] = x[i];
    }

    if(j >= 0 && j < n && i>n){
    assert(0);
    }
  

}
