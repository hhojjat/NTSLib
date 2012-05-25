#include<assert.h>

int main() {
	int x;
	int d;
	x = 0;
	d = 1;

	while(1) {
		assert(0 <= x && x <= 1000);
		if (x == 0) d=1;
		if (x == 1000) d=-1;
		x +=d;
	}
	return 1;
}
