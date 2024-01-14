kernel void insertion(global int* v, unsigned int n, unsigned int CUTOFF_SIZE) {
	unsigned int id = get_global_id(0);
	unsigned int lim_inf = id * CUTOFF_SIZE;

	unsigned int i = lim_inf;
	unsigned int lim_sup = lim_inf + CUTOFF_SIZE;

	//Insertion Sort a bloques de CUTOFF_SIZE de tamaño
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

kernel void agustin_merge(global int *v, unsigned int n,global int* res, unsigned int CUTOFF_SIZE) {

	for (unsigned int i = 2; i <= n/CUTOFF_SIZE; i *= 2) {

		//Threads que usas en cada nivel del arbol por merge
		unsigned int num_threads = i/2;
		unsigned int id = get_global_id(0);
		//Asignar el id a la parte del vector correspondiente
		unsigned int part = (id - id%num_threads) / num_threads;
		//Dentro de la seccion del vector, identificar los threads 
		unsigned int id_ins = id%num_threads;

		//Posicion Inicial del Vector
		unsigned int beg = part*CUTOFF_SIZE*i;
		//Posicion Final del Vector
		unsigned int end = beg + CUTOFF_SIZE * i  - 1;
		//Posicion del Medio
		unsigned int mid = beg + CUTOFF_SIZE * (i/2) - 1;
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


		//if (i == n/CUTOFF_SIZE) printf("part: %d, id: %d, idx: %d, end: %d,  x: %d, y: %d, id_ins: %d, beg: %d, mid: %d, end: %d, DiagNum: %d\n", part, id, idx, idx + steps - 1,  j, k, id_ins, beg, mid, end, DiagNum);

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

		idx = beg + DiagNum;

		//Poner de vuelta al vector
		for (int a = idx; a < (idx + steps); ++a) v[a] = res[a];
		barrier(CLK_GLOBAL_MEM_FENCE);
	}
}

kernel void merge(global int *v, unsigned int n, global int* res, unsigned int CUTOFF_SIZE){


	for (unsigned int i = 2; i <= n/CUTOFF_SIZE; i *= 2) {
		unsigned int id = get_global_id(0);
		unsigned int beg = id*CUTOFF_SIZE*i;

		if (beg >= n) return;

		unsigned int end = beg + CUTOFF_SIZE * i  - 1;
		unsigned int mid = beg + CUTOFF_SIZE * (i/2) - 1;
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


		for (int a = beg; a <= end; ++a) v[a] = res[a];
		barrier(CLK_GLOBAL_MEM_FENCE);

		
	}

	
}
