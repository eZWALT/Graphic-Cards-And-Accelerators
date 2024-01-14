#!/bin/bash
### Directivas para el gestor de colas (Las que te comes)
#SBATCH --job-name=agustin
#SBATCH -D . 
#SBATCH --output=submit_cl.o%j 
#SBATCH --error=submit_cl.e%j
#SBATCH -A cuda
#SBATCH -p cuda 
#SBATCH --gres=gpu:1
#Directivas para el gestor de colas (Las que te comes)

# File paths for CL_SIZEI_MERGE
CL_SIZEI_MERGE_0="./experimentos/opencl/size_i/cl_n25_merge_sizei_0.txt"
CL_SIZEI_MERGE_1="./experimentos/opencl/size_i/cl_n25_merge_sizei_1.txt"
CL_SIZEI_MERGE_2="./experimentos/opencl/size_i/cl_n25_merge_sizei_2.txt"

# File paths for CL_N_MERGE
CL_N_MERGE_0="./experimentos/opencl/n/cl_sizei_merge_n_0.txt"
CL_N_MERGE_1="./experimentos/opencl/n/cl_sizei_merge_n_1.txt"
CL_N_MERGE_2="./experimentos/opencl/n/cl_sizei_merge_n_2.txt"

# File paths for CL_SIZEI_PATH
CL_SIZEI_PATH_0="./experimentos/opencl/size_i/cl_n25_path_sizei_0.txt"
CL_SIZEI_PATH_1="./experimentos/opencl/size_i/cl_n25_path_sizei_1.txt"
CL_SIZEI_PATH_2="./experimentos/opencl/size_i/cl_n25_path_sizei_2.txt"

# File paths for CL_N_PATH
CL_N_PATH_0="./experimentos/opencl/n/cl_sizei_path_n_0.txt"
CL_N_PATH_1="./experimentos/opencl/n/cl_sizei_path_n_1.txt"
CL_N_PATH_2="./experimentos/opencl/n/cl_sizei_path_n_2.txt"

CL_BLOCK_MERGE_0="./experimentos/opencl/block/cl_block_merge_0.txt"
CL_BLOCK_MERGE_1="./experimentos/opencl/block/cl_block_merge_1.txt"
CL_BLOCK_MERGE_2="./experimentos/opencl/block/cl_block_merge_2.txt"

CL_BLOCK_PATH_0="./experimentos/opencl/block/cl_block_path_0.txt"
CL_BLOCK_PATH_1="./experimentos/opencl/block/cl_block_path_1.txt"
CL_BLOCK_PATH_2="./experimentos/opencl/block/cl_block_path_2.txt"

# Truncate files
truncate -s 0 "$CL_SIZEI_MERGE_0"
truncate -s 0 "$CL_SIZEI_MERGE_1"
truncate -s 0 "$CL_SIZEI_MERGE_2"
truncate -s 0 "$CL_N_MERGE_0"
truncate -s 0 "$CL_N_MERGE_1"
truncate -s 0 "$CL_N_MERGE_2"
truncate -s 0 "$CL_SIZEI_PATH_0"
truncate -s 0 "$CL_SIZEI_PATH_1"
truncate -s 0 "$CL_SIZEI_PATH_2"
truncate -s 0 "$CL_N_PATH_0"
truncate -s 0 "$CL_N_PATH_1"
truncate -s 0 "$CL_N_PATH_2"
truncate -s 0 "$CL_BLOCK_MERGE_0"
truncate -s 0 "$CL_BLOCK_MERGE_1"
truncate -s 0 "$CL_BLOCK_MERGE_2"
truncate -s 0 "$CL_BLOCK_PATH_0"
truncate -s 0 "$CL_BLOCK_PATH_1"
truncate -s 0 "$CL_BLOCK_PATH_2"


# SIZEI experiment
for i in {1..12}; do
	./opencl_sort.exe "$i" 25 10 0 0 0 >> "$CL_SIZEI_PATH_0"
	./opencl_sort.exe "$i" 25 10 0 0 1 >> "$CL_SIZEI_PATH_1"
	./opencl_sort.exe "$i" 25 10 0 0 2 >> "$CL_SIZEI_PATH_2"
done

#N experiment
for i in {15..27};do
	./opencl_sort.exe 1 $i 9 0 0 0 >> $CL_N_PATH_0
	./opencl_sort.exe 1 $i 9 0 0 1 >> $CL_N_PATH_1
	./opencl_sort.exe 1 $i 9 0 0 2 >> $CL_N_PATH_2
done

#BLOCK SIZE experiment
for i in {1..10};do
	./opencl_sort.exe 1 25 $i 0 0 0 >> $CL_BLOCK_PATH_0
	./opencl_sort.exe 1 25 $i 0 0 1 >> $CL_BLOCK_PATH_1
	./opencl_sort.exe 1 25 $i 0 0 2 >> $CL_BLOCK_PATH_2
done
