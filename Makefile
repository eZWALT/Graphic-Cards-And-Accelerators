CUDA_HOME   = /Soft/cuda/12.2.2

NVCC        = $(CUDA_HOME)/bin/nvcc
NVCC_FLAGS  = -O3 -Wno-deprecated-gpu-targets -I$(CUDA_HOME)/include -gencode arch=compute_86,code=sm_86 --ptxas-options=-v -I$(CUDA_HOME)/sdk/CUDALibraries/common/inc 
LD_FLAGS    = -lcudart -Xlinker -rpath,$(CUDA_HOME)/lib64 -I$(CUDA_HOME)/sdk/CUDALibraries/common/lib
GCC_FLAGS = -O3

CUDA_EXE    = cuda_sort.exe
CUDA_OBJ    = cuda_sort.o 
OPENCL_EXE  = opencl_sort.exe
OPENCL_OBJ  = opencl_sort.o 
CUDA_FIRST_EXE    = cudaFirstMerge.exe
CUDA_FIRST_OBJ    = cudaFirstMerge.o 
CUDA_FIRST_BLOCK_EXE    = cudaFirstMergeBlock.exe
CUDA_FIRST_BLOCK_OBJ    = cudaFirstMergeBlock.o 
CUDA_PATH_EXE    = cudaPathMerge.exe
CUDA_PATH_OBJ    = cudaPathMerge.o 
CUDA_PATH_BLOCK_EXE    = cudaPathMergeBlock.exe
CUDA_PATH_BLOCK_OBJ    = cudaPathMergeBlock.o 

default: all

cudaFirst : cudaFirstMerge.cu
	$(NVCC) -c -o cudaFirstMerge.o cudaFirstMerge.cu $(NVCC_FLAGS)
	$(NVCC) $(CUDA_FIRST_OBJ) -o $(CUDA_FIRST_EXE) $(LD_FLAGS)
	rm cudaFirstMerge.o

cudaFirstBlock : cudaFirstMergeBlock.cu
	$(NVCC) -c -o cudaFirstMergeBlock.o cudaFirstMergeBlock.cu $(NVCC_FLAGS)
	$(NVCC) $(CUDA_FIRST_BLOCK_OBJ) -o $(CUDA_FIRST_BLOCK_EXE) $(LD_FLAGS)
	rm cudaFirstMergeBlock.o

cudaPath : cudaPathMerge.cu
	$(NVCC) -c -o cudaPathMerge.o cudaPathMerge.cu $(NVCC_FLAGS)
	$(NVCC) $(CUDA_PATH_OBJ) -o $(CUDA_PATH_EXE) $(LD_FLAGS)
	rm cudaPathMerge.o

cudaPathBlock : cudaPathMergeBlock.cu
	$(NVCC) -c -o cudaPathMergeBlock.o cudaPathMergeBlock.cu $(NVCC_FLAGS)
	$(NVCC) $(CUDA_PATH_BLOCK_OBJ) -o $(CUDA_PATH_BLOCK_EXE) $(LD_FLAGS)
	rm cudaPathMergeBlock.o

opencl: opencl_sort.c
	gcc -O3 -o opencl_sort.exe opencl_sort.c -lOpenCL

seq: Seq_sort.c
	gcc -O3 -o seq_sort.exe Seq_sort.c
	
clean:
	rm -rf *.o $(EXE)

ultraclean:
	rm -rf *.o *.exe
	rm submit*	
