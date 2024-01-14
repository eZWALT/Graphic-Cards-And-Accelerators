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

sizeNormal=12
sizeRandom=3
sizeBack=3


for i in {15..27}; do
	./cudaFirstMergeBlock.exe $i $sizeNormal 0 10
done

echo "======================="

for i in {15..27}; do
	./cudaFirstMergeBlock.exe $i $sizeRandom 1 10
done

echo "======================="

for i in {15..27}; do
	./cudaFirstMergeBlock.exe $i $sizeBack 2 10
done
