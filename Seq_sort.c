#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/times.h>
#include <sys/resource.h>

float GetTime(void) {
  struct timeval tim;
  struct rusage ru;
  getrusage(RUSAGE_SELF, &ru);
  tim=ru.ru_utime;
  return ((double)tim.tv_sec + (double)tim.tv_usec / 1000000.0)*1000.0;
}

void insertion(int* v, int a, int b) {
	int lim_inf = a;

	int i = lim_inf;
	int lim_sup = b+1;

	//Insertion Sort a bloques de size_i de tamaño
	while (i < lim_sup) {
		int x = v[i];
		int j = i - 1;
		
		while (j >= lim_inf && v[j] > x) {
			v[j+1] = v[j];
			--j;
		}
		v[j+1] = x;
		++i;
	}
	
}

void merge(int *v, int *aux, int a, int mid, int b) {

	int i = a;
	int j = mid + 1;

	int idx = i;

	while (i <= mid && j <= b) {

		if (v[i] <= v[j]) aux[idx++] = v[i++];
		else aux[idx++] = v[j++];
	}

	while (i <= mid) aux[idx++] = v[i++];
	while (j <= b) aux[idx++] = v[j++];


	for (int k = a; k <= b; ++k) v[k] = aux[k];
}



void multisort(int *v, int* aux, int i, int j, unsigned int size_i) {

	if (j-i+1 == size_i) insertion(v, i, j);

	else {
		int mid = i + (j-i)/2;
		multisort(v, aux, i, mid, size_i);
		multisort(v, aux, mid+1, j, size_i);
		merge(v, aux, i, mid, j);
	}
}







int main(int argc, char** argv) {

	if (argc != 4) {
		printf("Número de parámetros no válido\n");
		return -1;
	}

	int n = 1 << atoi(argv[1]);
	unsigned int size_i = 1 << atoi(argv[2]);

	int *v = (int *)malloc(n*sizeof(int));
	int *aux = (int *)malloc(n*sizeof(int));

	srand(21364);
	const unsigned int sorted_mode = 0;
	const unsigned int random_mode = 1;
	const unsigned int sorted_back_mode = 2;
	const unsigned int mode = atoi(argv[3]);


	if (mode == random_mode) for (unsigned int i = 0; i < n; ++i) v[i] = rand();
	else if (mode == sorted_mode) for (unsigned int i = 0; i < n; ++i) v[i] = i;
	else for (unsigned int i = 0; i < n; ++i) v[i] = n - i;

	float t1, t2;


	t1 = GetTime();
	multisort(v, aux, 0, n-1, size_i);
	t2 = GetTime();

	printf("n: 2^%s, size_i: %d\n", argv[1], size_i); 
	printf("Elapsed Sequential Time: %f \n", t2 - t1);

	free(v);
	free(aux);
}
