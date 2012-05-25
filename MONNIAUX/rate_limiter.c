#include <assert.h>

int __NdetValInRange(int,int);


int main (int argc, char ** argv) {
  int x_old = 0;
  while (1) {
    int x = __NdetValInRange(-100, 100);
    if (x > x_old+10) x = x_old+10;
    if (x < x_old-10) x = x_old-10;
    x_old = x;
    assert(x <= 100 && x>= -100);
 } 

}


