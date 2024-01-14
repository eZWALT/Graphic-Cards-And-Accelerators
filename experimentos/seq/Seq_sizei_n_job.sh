#!/bin/bash 
### Directivas para el gestor de colas (Las que te comes)
#SBATCH --job-name=seq_n_job 
#SBATCH -D . 
#SBATCH --output=submit-seq-n-job.o%j 
#SBATCH --error=submit-seq-n-job.e%j
#SBATCH -A cuda
#SBATCH -p cuda 
#SBATCH --gres=gpu:1

sizeNormal=12
sizeRandom=6
sizeBack=3

for i in {15..27}; do
	./seq_sort.exe $i $sizeNormal 0
done

echo "==================="

for i in {15..27}; do
	./seq_sort.exe $i $sizeRandom 1
done

echo "==================="

for i in {15..27}; do
	./seq_sort.exe $i $sizeBack 2
done

echo "==================="
