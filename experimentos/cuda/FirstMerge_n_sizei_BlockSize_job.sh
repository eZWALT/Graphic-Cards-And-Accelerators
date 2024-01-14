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

./cudaFirstMergeBlock.exe 25 $sizeNormal 0 0

for i in {1..10}; do
	./cudaFirstMergeBlock.exe 25 $sizeNormal 0 $i 
done

echo "======================="

./cudaFirstMergeBlock.exe 25 $sizeRandom 1 0

for i in {1..10}; do
	./cudaFirstMergeBlock.exe 25 $sizeRandom 1 $i
done

echo "======================="

./cudaFirstMergeBlock.exe 25 $sizeBack 2 0

for i in {1..10}; do
	./cudaFirstMergeBlock.exe 25 $sizeBack 2 $i
done
