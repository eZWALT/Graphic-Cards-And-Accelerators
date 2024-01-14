#!/bin/bash

### Directivas para el gestor de colas
#SBATCH --job-name=CUDA_Sort
#SBATCH -D .
#SBATCH --output=submit-CUDA_Sort.o%j
#SBATCH --error=submit-CUDA_Sort.e%j
#SBATCH -A cuda
#SBATCH -p cuda
#SBATCH --gres=gpu:1

export PATH=/Soft/cuda/12.2.2/bin:$PATH

for i in {1..12}; do
	./cudaFirstMerge.exe 25 $i 0
done

echo "===================="

for i in {1..12}; do
	./cudaFirstMerge.exe 25 $i 1
done

echo "===================="

for i in {1..12}; do
	./cudaFirstMerge.exe 25 $i 2
done
