#include <stdio.h>
#include <stdlib.h>
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
__global__ void PathMerge(int *v, unsigned int n, int *res, unsigned int size_i, unsigned int i) {

		//Threads que usas en cada nivel del arbol por merge
		unsigned int num_threads = i/2;
		unsigned int id = threadIdx.x + blockDim.x * blockIdx.x;
		//Asignar el id a la parte del vector correspondiente
		unsigned int part = (id - id%num_threads) / num_threads;
		//Dentro de la seccion del vector, identificar los threads 
		unsigned int id_ins = id%num_threads;

		//Posicion Inicial del Vector
		unsigned int beg = part*size_i*i;
		//Posicion Final del Vector
		unsigned int end = beg + size_i * i  - 1;
		//Posicion del Medio
		unsigned int mid = beg + size_i * (i/2) - 1;
		//Los vectores ordenados van de v[beg ... mid], v[mid+1...end]

		//Tamaño de un vector
		unsigned int n_ind = mid - beg + 1;
		//La Diagonal que le corresponde
		unsigned int DiagNum = id_ins * 2 * n_ind /num_threads;

		unsigned int st[2], ed[2], pt[2];
		//Punto inicio de la diagonal
		st[0] = DiagNum > n_ind ? n_ind : DiagNum;
		st[1] = DiagNum > n_ind ? DiagNum - n_ind : 0;
		st[0] += beg;
		st[1] += beg;

		//Punto final de la diagonal
		ed[0] = st[1];
		ed[1] = st[0];

		//Punto medio para hacer busqueda binaria
		pt[1] = (st[1] + ed[1]) / 2;
		pt[0] = st[0] - (pt[1] - st[1]);
		//Busqueda binaria mientras haya dos casillas en la diagonal
		while (st[1] + 1 < ed[1]) {
			pt[1] = (st[1] + ed[1]) / 2;
			pt[0] = st[0] - (pt[1] - st[1]);

			//Sumar n_ind para coger los elementos del otro vector
			if (v[pt[0]] > v[pt[1] + n_ind - 1]) {
				if (v[pt[0] - 1] <= v[pt[1] + n_ind]) break;
				else {
					st[0] = pt[0];
					st[1] = pt[1];
				}
			}

			else {
				ed[0] = pt[0];
				ed[1] = pt[1];
			}
		}

		//En caso de que haya una solo casilla, decidir (si has llegado hasta aqui deberias de solo mirar los extremos de las diagonales)
		if (ed[1] - st[1] == 1) {
			if (v[st[0] - 1] <=  v[st[1] + n_ind]) {
				pt[0] = st[0];
				pt[1] = st[1];
			}

			else {
				pt[0] = ed[0];
				pt[1] = ed[1];
			}
		}


		//Cada thread hace un numero igual de iteraciones
		unsigned int aux = 0;
		unsigned int steps = 2 * n_ind/num_threads;

		//Posicion del vector para comenzar
		unsigned int idx = beg + DiagNum;
		unsigned int j = pt[0];
		unsigned int k = pt[1] + n_ind;



		//Merge normal
		while (aux < steps && j <= mid && k <= end) {

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

			++aux;
		}
		
		while(aux < steps && j <= mid) {
			res[idx] = v[j];
			++idx;
			++j;
			++aux;
		}

		while(aux < steps && k <= end) {
			res[idx] = v[k];
			++idx;
			++k;
			++aux;
		}

}




int main(int argc, char** argv) {

	if (argc != 5) {
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
	const unsigned int block_size = 1024 / (1 << atoi(argv[4]));
	unsigned int block = threads / block_size;

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
		unsigned int block_merge = threads_merge / block_size;
		if (block_merge == 0) block_merge = 1;
		if (!b) PathMerge<<<block_merge, threads_merge/block_merge>>>(d_v, n, d_aux, size_i, i);
		else PathMerge<<<block_merge, threads_merge/block_merge>>>(d_aux, n, d_v, size_i, i);
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
