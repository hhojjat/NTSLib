#include <assert.h>
int NonDetInt();
//int __BLAST_NONDET;

int main(void){
  
  int x,y;
  
  x = 0;
  y = 0;
  
  while(NonDetInt()){
    x++; y++;
  }
  
  while(x > 0){
    x--;
    y--;
  }
  
  if(y != 0){
  assert(0);
  }

  return 1;

}
