#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/times.h>
#include <sys/resource.h>
#include <CL/cl.h> 

#define KERNEL_FILE "opencl_sort.cl"
#define INSERTION_KERNEL_FUNC "insertion"
#define MERGE_KERNEL_FUNC "merge"
#define AGUSTIN_KERNEL_FUNC "agustin_merge"
#define CL_TARGET_OPENCL_VERSION 300
/*
	1. cuando nos hareis tour por el fuckign bsc
	2. Que experimentos nos recomiendas
	3. Que variables os interesan mas
	4. Decirle a Dani que me envie un audio de buen viaje desde tu móvil (Alex)
	   Audio start: prigao.... espero que vayan bien las pringles... :-P audio end.
	5. Cuando intenté medir tiempos en CUDA me daba tiempo 0.00000, pregunta a alguien que lo mire. Quizá el tiempo es muy pequeño y el SpeedUp es tan grande como la sabiduría de Conrado (Alex)
	6. He creado un archivo del MultiSort en secuencial (MultiSortSeq.c) pero creo que no es justo compararlo con la versión de CUDA ya que te comes la altura del árbol como tiempo la cuál cosa en CUDA no, relacionado con esto quizá sería curioso ver el SpeedUp de implementarlo igual que en CUDA (Alex)
	7. La gracia de nuestro algoritmo es que no pierdes el tiempo en buscar el caso base, directamente vas hacia él y construyes el árbol hacia arriba. En el MultiSortSeq.c te recorres el árbol hasta llegar al caso base, podría ser buena comparativa mirar cuál de las dos versiones es mejor (Alex)
	8. No Dani, mi abuela tiene cáncer terminal no puede ir a BitsXLaMarató
	   Tela tela.... que no te oiga tu abuela... 
	9. Implementé las dos formas de recorrerte el árbol en secuencial (comenzando por la raíz y comenzando por los casos base) por si Dani nos dice que podría ser buena comparativa mirar cuál de las dos formas es mejor. Ya paso que me voy al LIDL a comprar unas Pringles para el Viaje. 
*/

//Funcion generica para el tratamiento de errores OPENCL de manera simple
void check_cl_error(cl_int status, const char* msg){
	if(status != CL_SUCCESS){
		fprintf(stderr, "%s: %d\n", msg, status);
		exit(-1);
	}
	return;
}
//Funcion generica simple para el tratamiento de errores de malloc
void check_for_malloc_error(void * pointer, const char* msg){
	if(!pointer){
		fprintf(stderr, "Fatal error in %s malloc\n", msg);
		exit(-1);
	}
}
float GetTime(void) {
  struct timeval tim;
  struct rusage ru;
  getrusage(RUSAGE_SELF, &ru);
  tim=ru.ru_utime;
  return ((double)tim.tv_sec + (double)tim.tv_usec / 1000000.0)*1000.0;
}

unsigned int CUTOFF_SIZE = 64;
unsigned int N = 1 << 25;
unsigned int BLOCK_SIZE = 1 << 10;
unsigned int PROFILING = 1;
unsigned int USE_NORMAL_MERGE = 1;
unsigned int SORTING_MODE = 0;

int main(int argc, char* argv[]){
	//Alumnos de TGA del futuro, que sepais que NVIDIA esta metiendo mucha pasta y Ikea subvenciona OpenCL (by Walter J.T.V)
	//Apuntaros a BitsXLaMarató o Dani os reventará el kernel de un puñetazo en el hígado (by Alex H)
	
	
	srand(21364);
	//Tratamiento de los parametros del programa
	if(argc != 1){
		if(argc == 7){
			CUTOFF_SIZE = 1 << atoi(argv[1]);
			N = 1 << atoi(argv[2]);
			BLOCK_SIZE = 1 << atoi(argv[3]);
			PROFILING = atoi(argv[4]);
			USE_NORMAL_MERGE = atoi(argv[5]);
			SORTING_MODE = atoi(argv[6]);
		}
		else{
			printf("Input incorrecto...\n");
			exit(-1);
		}
	}
	if(PROFILING) printf("OPENCL (BitsXLaMarato)\n");
	
	//Crea los arrays de HOST y los incializa
	int* host_v = (int *) malloc (N * sizeof(int));
	check_for_malloc_error(host_v, "host_v");
	if(SORTING_MODE == 0) for(unsigned int i= 0; i < N; ++i) host_v[i] = i;
	else if(SORTING_MODE == 1) for(unsigned int i = 0; i < N; ++i) host_v[i] = rand();
	else if(SORTING_MODE == 2) for(unsigned int i = 0; i <N; ++i) host_v[i] = N - i;
	else exit(-21364);


	/*
	 * OPENCL SETUP: Cuantas plataformas (1), cuantos devices (1), Contexto, Cola, Kernel...
	^*/

	//Asigna una plataforma
	cl_platform_id platform;
	clGetPlatformIDs(1, &platform, NULL);
	cl_int platform_status = platform != NULL ? CL_SUCCESS : CL_INVALID_PLATFORM;
	check_cl_error(platform_status, "Failed to establish a platform");
	//Asigna ID de 1 GPU
	cl_device_id device;
	clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
	cl_int device_status = device != NULL ? CL_SUCCESS : CL_INVALID_DEVICE;
	check_cl_error(device_status, "Failed to get all the devices");
	//Asigna un contexto
	cl_int context_status;
	cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &context_status);
	check_cl_error(context_status, "Failed to create OpenCL context");
	//Crea una cola de comandos
	cl_int queue_status;
	const cl_queue_properties properties[] = {CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0}; 
	cl_command_queue queue = clCreateCommandQueueWithProperties(context,device,properties, &queue_status);
	check_cl_error(queue_status, "Failed to create OpenCL command queue");
	//Lectura del kernel estilo vertex shader en OpenGL
	FILE * kernel_file = fopen(KERNEL_FILE, "r");
	if(! kernel_file){
		perror("Failed to open the kernel file");
		exit(-1);
	}
	//Obtenemos el tamaño del kernel (Parametro necesario a posteriori)
	fseek(kernel_file, 0 , SEEK_END); //Va al final del fichero
	size_t kernel_size = ftell(kernel_file); //Indica la posicion del puntero respecto inicio
	rewind(kernel_file); //Resetea el puntero al inicio
	//Guardamos el fichero en un buffer
	char * kernel_buffer = (char *) malloc(kernel_size + 1);
	check_for_malloc_error(kernel_buffer, "Kernel Buffer");
	kernel_buffer[kernel_size] = '\0'; //El ultimo carácter debe ser un null terminator
	size_t elements_read = fread(kernel_buffer, sizeof(char), kernel_size, kernel_file);
	fclose(kernel_file);
	
	const char * program_buffer = kernel_buffer;
	//Compilacion del kernel opencl y log de errores
	cl_int program_status;
	cl_program program = clCreateProgramWithSource(context,1, &program_buffer, &kernel_size, &program_status);
	check_cl_error(program_status, "Failed to create OpenCL program");
	cl_int build_status = clBuildProgram(program, 1, &device, NULL, NULL, NULL);

	if(build_status != CL_SUCCESS){
		fprintf(stderr, "Failed to build OpenCL program, log:\n");
		size_t log_size;
		clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
		char* program_log = (char*) malloc(log_size+1);
		if(program_log){
			program_log[log_size] = '\0';
			clGetProgramBuildInfo(program,device,CL_PROGRAM_BUILD_LOG, log_size, program_log, NULL);
			fprintf(stderr, "%s\n", program_log);

			free(program_log);
		}
		else check_for_malloc_error(program_log, "Program LOG");
	}
	//Creacion de los tres objetos kernels a partir del codigo OpenCL compilado
	cl_int insertion_kernel_status, merge_kernel_status, agustin_kernel_status;
	cl_kernel insertion_kernel = clCreateKernel(program, INSERTION_KERNEL_FUNC, &insertion_kernel_status);
	check_cl_error(insertion_kernel_status, "Failed to create Insertion  Kernel");
	cl_kernel merge_kernel  = clCreateKernel(program, MERGE_KERNEL_FUNC, &merge_kernel_status);
	check_cl_error(merge_kernel_status, "Failed to create Merge  Kernel");
	cl_kernel agustin_kernel = clCreateKernel(program, AGUSTIN_KERNEL_FUNC, &agustin_kernel_status);
	check_cl_error(agustin_kernel_status, "Failed to create Agustin Kernel");

	//Movimiento de datos HOST -> DEVICE, creacion de objetos de memoria y toma de tiempos
	cl_mem device_v = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, N * sizeof(int), host_v, &context_status);
	check_cl_error(context_status, "Failed to create device_v");
	cl_mem device_aux = clCreateBuffer(context, CL_MEM_READ_WRITE, N * sizeof(int), NULL, &context_status);
	check_cl_error(context_status, "Failed to create device_aux");

	cl_event h2d_event;
	cl_int h2d_status = clEnqueueWriteBuffer(queue, device_v, CL_FALSE, 0, N * sizeof(int), host_v, 0, NULL, &h2d_event);
	clWaitForEvents(1, &h2d_event);
	check_cl_error(h2d_status, "Failed to enqueue host-to-device memory transfer");

//Definicion de los tamaños de ejecucion de los kernels
	unsigned int threads = N/CUTOFF_SIZE;
	unsigned int blocks = threads/BLOCK_SIZE;
	if(blocks == 0) blocks = 1;

	unsigned int threads_merge = threads/2;
	unsigned int blocks_merge = threads_merge/BLOCK_SIZE;
	if(blocks_merge == 0) blocks_merge = 1;

	size_t insertion_global_size = threads;
	size_t insertion_local_size = threads/blocks;

	size_t merge_global_size = threads_merge;
	size_t merge_local_size = threads_merge/blocks_merge;

	size_t agustin_global_size = merge_global_size;
	size_t agustin_local_size = merge_local_size;
	
	//Valores de los argumentos de las funciones Kernel y comprobacion de errores
	cl_int arg_status;
	arg_status = clSetKernelArg(insertion_kernel, 0, sizeof(cl_mem), &device_v);
	check_cl_error(arg_status, "Failed to set insertion_kernel argument 0");
	arg_status = clSetKernelArg(insertion_kernel, 1, sizeof(unsigned int), &N);
	check_cl_error(arg_status, "Failed to set insertion_kernel argument 1");
	arg_status = clSetKernelArg(insertion_kernel, 2, sizeof(unsigned int), &CUTOFF_SIZE);
	check_cl_error(arg_status, "Failed to set insertion_kernel argument 2");

	arg_status = clSetKernelArg(merge_kernel, 0, sizeof(cl_mem), &device_v);
	check_cl_error(arg_status, "Failed to set merge_kernel argument 0");
	arg_status = clSetKernelArg(merge_kernel, 1, sizeof(unsigned int), &N);
	check_cl_error(arg_status, "Failed to set merge_kernel argument 1");
	arg_status = clSetKernelArg(merge_kernel, 2, sizeof(cl_mem), &device_aux);
	check_cl_error(arg_status, "Failed to set merge_kernel argument 2");
	arg_status = clSetKernelArg(merge_kernel, 3, sizeof(unsigned int), &CUTOFF_SIZE);
	check_cl_error(arg_status, "Failed to set merge_kernel argument 3");


	//Ejecucion de kernels y tomas de tiempo
	cl_event insertion_event;
	cl_int enqueue_status = clEnqueueNDRangeKernel(queue,insertion_kernel, 1, NULL, &insertion_global_size, &insertion_local_size, 0, NULL, &insertion_event);
	clWaitForEvents(1, &insertion_event);
	check_cl_error(enqueue_status, "Failed to enqueue insertion kernel");

	cl_event merge_event;
	cl_double total_agustin_time = 0;
	unsigned int b = 0;
	if(USE_NORMAL_MERGE){
		cl_int enqueue_status2 = clEnqueueNDRangeKernel(queue, merge_kernel,1,NULL,&merge_global_size,&merge_local_size, 0, NULL, &merge_event);
		clWaitForEvents(1, &merge_event);
		check_cl_error(enqueue_status2, "Failed to enqueue merge kernel");
	}
	else{

		for(unsigned int i = 2; i <= N/CUTOFF_SIZE; i *= 2){
			unsigned int d_v_arg = !b ? 0: 2;
			unsigned int d_aux_arg = !b ? 2: 0;
			b = !b;

			arg_status = clSetKernelArg(agustin_kernel,d_v_arg, sizeof(cl_mem), &device_v);
			check_cl_error(arg_status, "Failed to set agustin_kernel argument 0");
			arg_status = clSetKernelArg(agustin_kernel, 1, sizeof(unsigned int), &N);
			check_cl_error(arg_status, "Failed to set agustin_kernel argument 1");
			arg_status = clSetKernelArg(agustin_kernel, d_aux_arg, sizeof(cl_mem), &device_aux);
			check_cl_error(arg_status, "Failed to set agustin_kernel argument 2");
			arg_status = clSetKernelArg(agustin_kernel, 3, sizeof(unsigned int), &CUTOFF_SIZE);
			check_cl_error(arg_status, "Failed to set agustin_kernel argument 3");
			cl_event agustin_event;
			cl_int enqueue_status_3 = clEnqueueNDRangeKernel(queue, agustin_kernel,1,NULL,&agustin_global_size,&agustin_local_size,0,NULL, &agustin_event);
			clWaitForEvents(1, &agustin_event);
			check_cl_error(enqueue_status_3, "Failed to enqueue agustin kernel");
			
			cl_ulong start_time, end_time;
			cl_int prof_status_start = clGetEventProfilingInfo(agustin_event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &start_time, NULL);
			cl_int prof_status_end = clGetEventProfilingInfo(agustin_event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &end_time, NULL);
			check_cl_error(prof_status_start, "Failed to get profile info (Start)");
			check_cl_error(prof_status_end, "Failed to get profile info (End)");
			//// Acumular tiempo de ejecución
			total_agustin_time += ((double)end_time - (double)start_time) * 1e-6;
		}
		
	}
	

	//Movimiento de datos DEVICE -> HOST y toma de tiempos

	clFinish(queue);
	cl_event d2h_event;
	cl_int read_status = clEnqueueReadBuffer(queue, !b ? device_v : device_aux, CL_FALSE, 0 , N * sizeof(int), host_v,0, NULL, &d2h_event);
	clWaitForEvents(1,&d2h_event);
	check_cl_error(read_status, "Failed to enqueue device-to-host memory transfer");

	
	//Wait for events to finish
	cl_ulong h2d_start, h2d_end, insertion_start, insertion_end, merge_start, merge_end, d2h_start, d2h_end;
	cl_double h2d_time, d2h_time, insertion_time, merge_time, total_gpu_time;
	//Calcular los tiempos de ejecución y anchos de banda (OPENCL MIDE TIEMPO EN NANOSEGUNDOS) 
	cl_int prof_status = clGetEventProfilingInfo(h2d_event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &h2d_start, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 1)");
	prof_status = clGetEventProfilingInfo(h2d_event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &h2d_end, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 2)");
	prof_status = clGetEventProfilingInfo(insertion_event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &insertion_start, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 3)");
	prof_status = clGetEventProfilingInfo(insertion_event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &insertion_end, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 4)");

	if(USE_NORMAL_MERGE){
		prof_status = clGetEventProfilingInfo(merge_event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &merge_start, NULL);
		check_cl_error(prof_status, "Failed to get profile info (Call 5)");
		prof_status = clGetEventProfilingInfo(merge_event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &merge_end, NULL);
		check_cl_error(prof_status, "Failed to get profile info (Call 6)");
		merge_time = ((double)merge_end - (double)merge_start) * 1e-6;
	}
	else merge_time = total_agustin_time;

	prof_status = clGetEventProfilingInfo(d2h_event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &d2h_start, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 7)");
	prof_status = clGetEventProfilingInfo(d2h_event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &d2h_end, NULL);
	check_cl_error(prof_status, "Failed to get profile info (Call 8)");
	
	
	//Computos de tiempo (SEGUNDOS) y anchos de banda (MB/s)
	h2d_time = ((double)h2d_end - (double)h2d_start) * 1e-9;
	d2h_time = ((double)d2h_end - (double)d2h_start) * 1e-6;
	insertion_time = ((double)insertion_end - (double)insertion_start) * 1e-6; 
	total_gpu_time = insertion_time + merge_time + d2h_time;
	d2h_time *= 1e-3;
	double h2d_bandwidth = (double) N * sizeof(unsigned int)/ (h2d_time * 1e6);
	double d2h_bandwidth = (double) N * sizeof(unsigned int)/ (d2h_time  * 1e6);

	double kernel_bandwidth = (double) N * sizeof(unsigned int) * 2 / ((insertion_time+merge_time) * 1e6);

	if(PROFILING){
		//Muestra los resultados al estilo PROFILING de eventos
		const char * selected_kernel = USE_NORMAL_MERGE ? MERGE_KERNEL_FUNC : AGUSTIN_KERNEL_FUNC;
		printf("HtoD transfer time & Bandwidth: %f s and %f MB/s\n", h2d_time, h2d_bandwidth);
		printf("DtoH transfer time & Bandwidth: %f s and %f MB/s\n", d2h_time, d2h_bandwidth);
		printf("Insertion kernel execution time: %f ms\n", insertion_time);
		printf("%s kernel execution time: %f ms\n",selected_kernel, merge_time);
		printf("Total GPU execution time: %f ms\n", total_gpu_time);
		printf("Parameters used: CUTOFF_SIZE:%d, N:%d\n", CUTOFF_SIZE, N);
	}
	else{
		//Muestra las estadisticas para usar en scripts
		printf("Modo: %d\n", SORTING_MODE); 
		printf("n: %d, size_i: %d\n", N, CUTOFF_SIZE); 
		printf("Tiempo Kernels: %f ms\n", insertion_time + merge_time); 
		printf("Ancho de Banda HtD: %f MB/s, Ancho de Banda Kernels: %f GB/s, Ancho de Banda DtH: %f MB/s\n", h2d_bandwidth, kernel_bandwidth, d2h_bandwidth);
	}
	
	//Liberar objetos OpenCL y punteros
	clReleaseMemObject(device_v);
	clReleaseMemObject(device_aux);
	clReleaseKernel(insertion_kernel);
	clReleaseKernel(merge_kernel);
	clReleaseProgram(program);
	clReleaseCommandQueue(queue);
	clReleaseContext(context);

	free(kernel_buffer);
	free(host_v);
	return 0;
}
