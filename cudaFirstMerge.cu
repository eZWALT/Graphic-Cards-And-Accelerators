#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <cuda.h>
#include <sys/times.h>
#include <sys/resource.h>


void CheckCudaError(char sms[], int line) {
  cudaError_t error;
 
  error = cudaGetLastError();
  if (error) {
    printf("(ERROR) %s - %s in %s at line %d\n", sms, cudaGetErrorString(error), __FILE__, line);
    exit(EXIT_FAILURE);
  }

  else {
	  printf("Ok jefe");
  }


}


__global__ void insertion(int *v, unsigned int n, unsigned int size_i) {
	unsigned int id = threadIdx.x + blockDim.x * blockIdx.x;

	unsigned int lim_inf = id * size_i;

	unsigned int i = lim_inf;
	unsigned int lim_sup = lim_inf + size_i;

	//Insertion Sort a bloques de size_i de tamaño
	while (i < lim_sup) {
		int x = v[i];
		int j = i - 1;

		while (j >= (int)lim_inf && v[j] > x) {
			v[j+1] = v[j];
			--j;
		}
		v[j+1] = x;
		++i;
	}

	
}

__global__ void merge(int *v, unsigned int n, int* res, unsigned int size_i, unsigned int i) {

		unsigned int id = threadIdx.x + blockDim.x * blockIdx.x;
		unsigned int beg = id*size_i*i;

		unsigned int end = beg + size_i * i  - 1;
		unsigned int mid = beg + size_i * (i/2) - 1;
		unsigned int j = beg;
		unsigned int k = mid + 1;
		unsigned int idx = beg;

		while (j <= mid && k <= end) {

			if (v[j] <= v[k]) {
				res[idx] = v[j];
				++idx;
				++j;
			}

			else {
				res[idx] = v[k];
				++idx;
				++k;
			}
		}
		
		while(j <= mid) {
			res[idx] = v[j];
			++idx;
			++j;
		}

		while(k <= end) {
			res[idx] = v[k];
			++idx;
			++k;
		}
	
}

int main(int argc, char** argv) {

	if (argc != 4) {
		printf("Número de parámetros no válido\n");
		return -1;
	}
	
	int *d_v;
	unsigned int n = 1 << atoi(argv[1]);
	unsigned int size_i = 1 << atoi(argv[2]);
	int *h_v = (int *)malloc(n*sizeof(int));
	int *d_aux;
	srand(21364);
	cudaEvent_t e1, e2, e3, e4, e5, e6;
	cudaEventCreate(&e1);
	cudaEventCreate(&e2);
	cudaEventCreate(&e3);
	cudaEventCreate(&e4);
	cudaEventCreate(&e5);
	cudaEventCreate(&e6);

	unsigned int threads = n / size_i;
	unsigned int block = threads / 1024;

	if (block == 0) block = 1;
	

	const unsigned int sorted_mode = 0;
	const unsigned int random_mode = 1;
	const unsigned int sorted_back_mode = 2;
	const unsigned int mode = atoi(argv[3]);


	if (mode == random_mode) for (unsigned int i = 0; i < n; ++i) h_v[i] = rand();
	else if (mode == sorted_mode) for (unsigned int i = 0; i < n; ++i) h_v[i] = i;
	else for (unsigned int i = 0; i < n; ++i) h_v[i] = n - i;

	cudaMalloc((void **)&d_v, n*sizeof(int));
	cudaMalloc((void **)&d_aux, n*sizeof(int));

	cudaEventRecord(e1, 0);
	cudaMemcpyAsync(d_v, h_v, n*sizeof(int), cudaMemcpyHostToDevice);
	cudaEventRecord(e2, 0);
	cudaEventSynchronize(e2);
	float HtD_t;
	cudaEventElapsedTime(&HtD_t, e1, e2);

	cudaEventRecord(e3, 0);
	insertion<<<block, threads/block>>>(d_v,n, size_i);
	unsigned int b = 0;

	for (unsigned int i = 2; i <= n/size_i; i *= 2) {
		unsigned int threads_merge = threads / i;
		unsigned int block_merge = threads_merge / 1024;
		if (block_merge == 0) block_merge = 1;
		if (!b) merge<<<block_merge, threads_merge/block_merge>>>(d_v, n, d_aux, size_i, i);
		else merge<<<block_merge, threads_merge/block_merge>>>(d_aux, n, d_v, size_i, i);
		b = !b;
	}
	cudaEventRecord(e4, 0);
	cudaEventSynchronize(e4);
	float kernel_t;
	cudaEventElapsedTime(&kernel_t, e3, e4);

	cudaEventRecord(e5, 0);
	if (b) cudaMemcpyAsync(h_v, d_aux, n*sizeof(int), cudaMemcpyDeviceToHost);
	else cudaMemcpyAsync(h_v, d_v, n*sizeof(int), cudaMemcpyDeviceToHost);
	cudaEventRecord(e6, 0);
	cudaEventSynchronize(e6);
	float DtH_t;
	cudaEventElapsedTime(&DtH_t, e5, e6);
	//for (unsigned int i = 0; i < n; ++i) printf("%d\n", h_v[i]);

	char s[10];
	if (mode == random_mode) strcpy(s, "Random");
	else if (mode == sorted_mode) strcpy(s, "Ordenado");
	else strcpy(s, "Al Revés");

	printf("Modo: %s\n", s); 
	printf("n: %d, size_i: %d\n", n, size_i); 
	printf("Tiempo Kernels: %f ms\n", kernel_t); 
	printf("Ancho de Banda HtD: %f GB/s, Ancho de Banda Kernels: %f GB/s, Ancho de Banda DtH: %f GB/s\n", (n*sizeof(unsigned int)) / (HtD_t * 1e6), (n*sizeof(unsigned int)) / ((kernel_t+DtH_t) * 1e6), (n*sizeof(unsigned int)) / (DtH_t * 1e6));

	free(h_v);
	cudaFree(d_v);
	cudaFree(d_aux);
}
